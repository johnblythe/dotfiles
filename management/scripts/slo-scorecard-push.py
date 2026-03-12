#!/usr/bin/env python3
"""
SLO Scorecard Push — updates the Confluence Observability Scorecard
with live SLO achievement data from Datadog.

Queries DD API for monitor-based SLOs (tagged slo-type:monitor),
extracts 30d status + error budget remaining, and updates:
  1. "SLO Achievement" table with live numbers
  2. "Customer Journey Domains" table with current state indicators

Usage:
  python3 scripts/slo-scorecard-push.py           # dry run (print only)
  python3 scripts/slo-scorecard-push.py --push     # update Confluence

Env vars: DD_API_KEY, DD_APP_KEY, DD_SITE (defaults to datadoghq.com)
Confluence creds: reads from ~/.config/jiratui/config.yaml
"""

import base64
import json
import os
import re
import ssl
import sys
import urllib.request
import urllib.error
from pathlib import Path

# Homebrew Python often lacks system certs — use certifi if available, else unverified
try:
    import certifi
    SSL_CONTEXT = ssl.create_default_context(cafile=certifi.where())
except ImportError:
    SSL_CONTEXT = ssl.create_default_context()
    SSL_CONTEXT.load_default_certs()
    # Fallback: if still broken, disable verification (local script, not a service)
    try:
        SSL_CONTEXT.load_default_certs()
    except Exception:
        SSL_CONTEXT = ssl._create_unverified_context()

# =============================================================================
# Config
# =============================================================================

CONFLUENCE_PAGE_ID = "2531786791"
DD_SITE = os.environ.get("DD_SITE", "datadoghq.com")
DD_API_KEY = os.environ.get("DD_API_KEY", "")
DD_APP_KEY = os.environ.get("DD_APP_KEY", "")

DOMAINS = ["access", "intake", "search", "logging", "fulfillment", "delivery"]

DOMAIN_TARGETS = {
    "access": 99.0,
    "intake": 98.0,
    "search": 99.0,
    "logging": 98.0,
    "fulfillment": 98.0,
    "delivery": 99.0,
}

# =============================================================================
# Confluence creds (from jiratui config, same as jira-lib.sh)
# =============================================================================

def load_confluence_creds():
    """Parse jiratui config without yaml dependency."""
    config_path = Path.home() / ".config" / "jiratui" / "config.yaml"
    creds = {}
    with open(config_path) as f:
        for line in f:
            line = line.strip()
            for key, field in [
                ("jira_api_username", "user"),
                ("jira_api_token", "token"),
                ("jira_api_base_url", "url"),
            ]:
                if line.startswith(key):
                    val = line.split(":", 1)[1].strip().strip("'\"")
                    creds[field] = val
    return creds


# =============================================================================
# Datadog API
# =============================================================================

def dd_request(path):
    url = f"https://api.{DD_SITE}{path}"
    req = urllib.request.Request(url, headers={
        "DD-API-KEY": DD_API_KEY,
        "DD-APPLICATION-KEY": DD_APP_KEY,
        "Content-Type": "application/json",
    })
    with urllib.request.urlopen(req, context=SSL_CONTEXT) as resp:
        return json.loads(resp.read())


def get_monitor_slos():
    """Fetch all monitor-based SLOs tagged slo-type:monitor."""
    data = dd_request("/api/v1/slo?tags=slo-type:monitor")
    slos = {}
    for slo in data.get("data", []):
        # Extract domain from tags
        domain = None
        for tag in slo.get("tags", []):
            if tag.startswith("domain:"):
                domain = tag.split(":")[1]
                break
        if domain and domain in DOMAINS:
            slos[domain] = slo
    return slos


def extract_slo_status(slo):
    """Extract 30d status and error budget from SLO data."""
    overall = slo.get("overall_status", [])
    thresholds = slo.get("thresholds", [])

    # Find 30d threshold
    status_30d = None
    error_budget = None
    for t in thresholds:
        if t.get("timeframe") == "30d":
            status_30d = t.get("sli_value")
            error_budget = t.get("error_budget_remaining")
            break

    # Fallback: use overall status if thresholds don't have sli_value
    if status_30d is None:
        status_30d = slo.get("overall_status", [{}])
        if isinstance(status_30d, list) and status_30d:
            status_30d = status_30d[0].get("sli_value")

    return {
        "status_30d": round(status_30d, 2) if status_30d is not None else None,
        "error_budget": round(error_budget, 2) if error_budget is not None else None,
        "name": slo.get("name", ""),
    }


def get_slo_data():
    """Fetch and process all domain SLO data."""
    slos = get_monitor_slos()
    results = {}
    for domain in DOMAINS:
        if domain in slos:
            results[domain] = extract_slo_status(slos[domain])
        else:
            results[domain] = {"status_30d": None, "error_budget": None, "name": ""}
    return results


# =============================================================================
# Status indicators
# =============================================================================

def status_emoji(actual, target):
    """Return status indicator based on SLO achievement vs target."""
    if actual is None:
        return "⚪ No data"
    if actual >= target:
        return "🟢 Meeting SLO"
    if actual >= target - 1.0:
        return "🟡 Warning"
    return "🔴 Below SLO"


def trend_indicator(error_budget):
    """Return trend based on error budget remaining."""
    if error_budget is None:
        return "--"
    if error_budget > 50:
        return "📈 Healthy"
    if error_budget > 20:
        return "📊 Watch"
    if error_budget > 0:
        return "📉 Burning"
    return "🔥 Exhausted"


# =============================================================================
# Confluence ADF
# =============================================================================

def text_node(text, bold=False):
    node = {"type": "text", "text": str(text)}
    if bold:
        node["marks"] = [{"type": "strong"}]
    return node


def paragraph(*children):
    return {"type": "paragraph", "content": list(children)}


def table_cell(*content_nodes):
    return {"type": "tableCell", "content": list(content_nodes)}


def table_header(*content_nodes):
    return {"type": "tableHeader", "content": list(content_nodes)}


def table_row(*cells):
    return {"type": "tableRow", "content": list(cells)}


def build_slo_achievement_table(slo_data):
    """Build ADF table for SLO Achievement section."""
    header = table_row(
        table_header(paragraph(text_node("Domain", bold=True))),
        table_header(paragraph(text_node("SLO", bold=True))),
        table_header(paragraph(text_node("30-Day Actual", bold=True))),
        table_header(paragraph(text_node("Error Budget Remaining", bold=True))),
        table_header(paragraph(text_node("Trend", bold=True))),
    )

    rows = [header]
    for domain in DOMAINS:
        d = slo_data[domain]
        target = DOMAIN_TARGETS[domain]
        actual = d["status_30d"]
        budget = d["error_budget"]

        actual_str = f"{actual}%" if actual is not None else "--"
        budget_str = f"{budget}%" if budget is not None else "--"
        trend = trend_indicator(budget)

        rows.append(table_row(
            table_cell(paragraph(text_node(domain.upper(), bold=True))),
            table_cell(paragraph(text_node(f"{target}%"))),
            table_cell(paragraph(text_node(actual_str))),
            table_cell(paragraph(text_node(budget_str))),
            table_cell(paragraph(text_node(trend))),
        ))

    return {"type": "table", "attrs": {"isNumberColumnEnabled": False, "layout": "default"}, "content": rows}


def build_domain_status_table(slo_data):
    """Build ADF table for Customer Journey Domains section."""
    domain_meta = {
        "access":      ("Can users log in?", "securityservices, cipui"),
        "intake":      ("Can work enter the system?", "intakeservices, fax, email, upload"),
        "search":      ("Can users find requests?", "searchservices"),
        "logging":     ("Is work being processed?", "workflow, camunda, ocr, nlp, artifacts"),
        "fulfillment": ("Is work getting completed?", "workflow, requestworker, approval queues"),
        "delivery":    ("Did output reach the right place?", "rspservices, esmd, back office, deliveryservices"),
    }

    header = table_row(
        table_header(paragraph(text_node("Domain", bold=True))),
        table_header(paragraph(text_node("What It Means", bold=True))),
        table_header(paragraph(text_node("Key Services", bold=True))),
        table_header(paragraph(text_node("SLO Target", bold=True))),
        table_header(paragraph(text_node("Current State", bold=True))),
    )

    rows = [header]
    for domain in DOMAINS:
        d = slo_data[domain]
        target = DOMAIN_TARGETS[domain]
        meaning, services = domain_meta[domain]
        state = status_emoji(d["status_30d"], target)

        rows.append(table_row(
            table_cell(paragraph(text_node(domain.upper(), bold=True))),
            table_cell(paragraph(text_node(meaning))),
            table_cell(paragraph(text_node(services))),
            table_cell(paragraph(text_node(f"{target}%"))),
            table_cell(paragraph(text_node(state))),
        ))

    return {"type": "table", "attrs": {"isNumberColumnEnabled": False, "layout": "default"}, "content": rows}


# =============================================================================
# Confluence API
# =============================================================================

def confluence_get_page(creds):
    """Fetch current page version and body."""
    url = f"{creds['url']}/wiki/api/v2/pages/{CONFLUENCE_PAGE_ID}?body-format=atlas_doc_format"
    req = urllib.request.Request(url)
    auth = f"{creds['user']}:{creds['token']}"
    req.add_header("Authorization", f"Basic {base64.b64encode(auth.encode()).decode()}")
    with urllib.request.urlopen(req, context=SSL_CONTEXT) as resp:
        return json.loads(resp.read())


def confluence_update_page(creds, title, body_adf, version):
    """Update Confluence page with new ADF body."""
    url = f"{creds['url']}/wiki/api/v2/pages/{CONFLUENCE_PAGE_ID}"
    payload = json.dumps({
        "id": CONFLUENCE_PAGE_ID,
        "status": "current",
        "title": title,
        "body": {
            "representation": "atlas_doc_format",
            "value": json.dumps(body_adf),
        },
        "version": {"number": version + 1, "message": "SLO scorecard auto-update"},
    })

    import base64
    auth = f"{creds['user']}:{creds['token']}"
    req = urllib.request.Request(url, data=payload.encode(), method="PUT", headers={
        "Authorization": f"Basic {base64.b64encode(auth.encode()).decode()}",
        "Content-Type": "application/json",
    })
    with urllib.request.urlopen(req, context=SSL_CONTEXT) as resp:
        return json.loads(resp.read())


def replace_table_in_adf(adf_content, section_heading, new_table):
    """Replace the first table after a given heading in ADF content."""
    content = adf_content.get("content", [])
    found_heading = False
    for i, node in enumerate(content):
        # Look for heading containing the section text
        if node.get("type") == "heading":
            heading_text = ""
            for child in node.get("content", []):
                heading_text += child.get("text", "")
            if section_heading.lower() in heading_text.lower():
                found_heading = True
                continue

        # Replace the first table after the heading
        if found_heading and node.get("type") == "table":
            content[i] = new_table
            return True

    return False


# =============================================================================
# Main
# =============================================================================

def main():
    push = "--push" in sys.argv
    verbose = "--verbose" in sys.argv or "-v" in sys.argv

    if not DD_API_KEY or not DD_APP_KEY:
        print("ERROR: DD_API_KEY and DD_APP_KEY env vars required")
        sys.exit(1)

    # 1. Fetch SLO data from Datadog
    print("Fetching SLO data from Datadog...")
    slo_data = get_slo_data()

    # 2. Print summary
    print("\n=== SLO Achievement (30d) ===")
    print(f"{'Domain':<14} {'Target':>7} {'Actual':>8} {'Budget':>8} {'Status'}")
    print("-" * 60)
    for domain in DOMAINS:
        d = slo_data[domain]
        target = DOMAIN_TARGETS[domain]
        actual = f"{d['status_30d']}%" if d["status_30d"] is not None else "--"
        budget = f"{d['error_budget']}%" if d["error_budget"] is not None else "--"
        status = status_emoji(d["status_30d"], target)
        print(f"{domain.upper():<14} {target:>6}% {actual:>8} {budget:>8} {status}")

    if not push:
        print("\nDry run — pass --push to update Confluence")
        return

    # 3. Fetch current page
    print("\nFetching Confluence page...")
    creds = load_confluence_creds()
    page = confluence_get_page(creds)
    version = page["version"]["number"]
    title = page["title"]
    body_adf = json.loads(page["body"]["atlas_doc_format"]["value"])

    if verbose:
        print(f"  Page version: {version}")
        print(f"  Content nodes: {len(body_adf.get('content', []))}")

    # 4. Build replacement tables
    slo_table = build_slo_achievement_table(slo_data)
    domain_table = build_domain_status_table(slo_data)

    # 5. Replace tables in ADF
    replaced_slo = replace_table_in_adf(body_adf, "SLO Achievement", slo_table)
    replaced_domain = replace_table_in_adf(body_adf, "Customer Journey Domains", domain_table)

    if not replaced_slo:
        print("WARNING: Could not find 'SLO Achievement' table in page")
    if not replaced_domain:
        print("WARNING: Could not find 'Customer Journey Domains' table in page")

    if not replaced_slo and not replaced_domain:
        print("ERROR: No tables replaced — aborting")
        sys.exit(1)

    # 6. Push update
    print("Updating Confluence page...")
    result = confluence_update_page(creds, title, body_adf, version)
    new_version = result.get("version", {}).get("number", "?")
    print(f"Done — page updated to version {new_version}")
    print(f"  https://datavant.atlassian.net/wiki/spaces/HealthSour/pages/{CONFLUENCE_PAGE_ID}")


if __name__ == "__main__":
    main()
