---
name: monitoring-gap
description: Detects monitoring gaps from Datadog alerts/incidents and creates Terraform monitor entries. PROACTIVELY suggest when reviewing alerts that show symptoms (queue backup, timeouts) but missing root cause monitors (error rates, deployment failures). Generates TF code, creates PR, and files Jira ticket.
---

# Monitoring Gap Detection Skill

Identify when Datadog alerts fire for symptoms but not root causes, then create the upstream monitors.

## Proactive Triggers

Watch for these signals during incident/alert review:
- Queue depth alerts without corresponding error rate monitors
- Timeout alerts without latency monitors
- Watchdog identifies deployment issues but no monitor exists
- "We should have caught this earlier"
- "The alert fired too late"
- Symptoms triggering before causes

When detected, ask: **"I notice we have monitoring for [symptom] but not [root cause]. Want me to create a Terraform monitor for the upstream signal?"**

## Explicit Usage

```
/monitoring-gap <service> <signal-type>
```

Example: `/monitoring-gap hs-pdfworker error-rate`

## Analysis Process

### 1. Identify the Gap

| Symptom Alert | Missing Upstream Monitor |
|---------------|--------------------------|
| Queue depth high | Service error rate |
| Timeouts | Latency percentiles |
| DLQ messages | Processing failures |
| Pod restarts | OOM/resource exhaustion |
| Downstream failures | Dependency health |

### 2. Gather Context from Datadog

Check Watchdog/APM for:
- Service name (e.g., `hs-pdfworker`)
- Resource/operation name (e.g., `listener.new_message`)
- Metric type (errors, hits, latency)
- Existing thresholds from similar monitors

### 3. Check Existing Terraform

Location: `~/code/healthsource/monitors/terraform/`

```bash
# Find existing monitors for similar services
grep -r "service_name" modules/datadog-hs-monitors-v2/*.tf
grep -r "error_rate\|error_percentage" modules/datadog-hs-monitors-v2/*.tf
```

Review patterns in:
- `custom_application_monitors.tf` - service-specific monitors
- `datadog_monitors.tf` - generic APM monitors
- `variables.tf` - variable definitions
- `environments/prod/main.tf` - config values

## Terraform Generation

### Required Changes (3 files)

#### 1. `modules/datadog-hs-monitors-v2/variables.tf`

Add to `custom_applications` object:
```terraform
<service>_error_rate = object({
  enable_alerting = optional(bool, false)
  critical        = optional(number, <default_critical>)
  warning         = optional(number, <default_warning>)
})
```

#### 2. `modules/datadog-hs-monitors-v2/custom_application_monitors.tf`

```terraform
resource "datadog_monitor" "<service>_error_rate" {
  name     = "[healthsource] <Service> Error Rate is too High"
  type     = "query alert"
  tags     = concat(["service:<service>", "team:healthsource"], local.common_monitor_tag_list)
  priority = <1|2>  # 1 for critical path, 2 for others
  query    = <<-EOT
    sum(last_5m):(
      sum:trace.<operation>.errors{${local.environment_filter},service:<service>}.as_count() /
      sum:trace.<operation>.hits{${local.environment_filter},service:<service>}.as_count()
    ) * 100 > ${var.monitors.custom_applications.<service>_error_rate.critical}
  EOT
  message  = <<-EOT
    {{#is_alert}}
    CRITICAL: <service> error rate is {{value}}%

    ### What This Means
    <impact description>

    ### Investigation Steps
    1. Check Watchdog for deployment correlation
    2. Review recent deployments
    3. Check APM traces for error details

    ### Useful Links
    - [APM Service](https://app.datadoghq.com/apm/services/<service>?env=${var.environment})
    - [APM Traces - Errors](https://app.datadoghq.com/apm/traces?query=service%3A<service>%20status%3Aerror%20env%3A${var.environment})
    - [Logs](https://app.datadoghq.com/logs?query=service%3A<service>%20status%3Aerror%20env%3A${var.environment})
    {{/is_alert}}

    {{#is_warning}}
    WARNING: <service> error rate elevated at {{value}}%. Monitor closely.
    {{/is_warning}}

    ${var.monitors.custom_applications.<service>_error_rate.enable_alerting ? local.slack_notification_name : ""}
  EOT

  monitor_thresholds {
    critical = var.monitors.custom_applications.<service>_error_rate.critical
    warning  = var.monitors.custom_applications.<service>_error_rate.warning
  }

  evaluation_delay         = 60
  groupby_simple_monitor   = false
  include_tags             = true
  notification_preset_name = "hide_query"
  require_full_window      = false
  notify_audit             = false
  notify_no_data           = false
}
```

#### 3. `environments/prod/main.tf`

Add to `monitors.custom_applications`:
```terraform
<service>_error_rate = {
  enable_alerting = true
  critical        = <threshold>
  warning         = <threshold>
}
```

## Create PR

```bash
cd ~/code/healthsource
git checkout -b monitoring/<service>-error-rate-monitor
git add monitors/terraform/
git commit -m "Add <service> error rate monitor

Adds upstream error rate monitoring for <service> to catch
failures before they manifest as queue backup or downstream issues.

Triggered by: <incident/alert description>
"
gh pr create --title "Add <service> error rate monitor" \
  --body "## Summary
- Adds error rate monitor for <service>
- Alerts at <critical>% error rate (warn at <warning>%)

## Context
During incident on <date>, we noticed <symptom> alerts fired but no
upstream error rate monitor existed. This creates the missing monitor.

## Testing
- [ ] terraform plan shows expected resources
- [ ] Monitor appears in Datadog after apply
"
```

## Create Jira Ticket

If PR needs review/approval, create tracking ticket:

```bash
acli jira workitem create \
  --project HEAL \
  --type Task \
  --summary "Add <service> error rate monitor" \
  --description "Add Datadog monitor for <service> error rate to catch failures upstream of queue depth alerts.

Context: <incident description>

PR: <pr-url>" \
  --labels ktlo
```

## Common Metric Patterns

| Monitor Type | Metric Pattern |
|-------------|----------------|
| APM Error Rate | `trace.<operation>.errors / trace.<operation>.hits` |
| Servlet Error Rate | `trace.servlet.request.errors / trace.servlet.request.hits` |
| Custom Metric Count | `<namespace>.<metric>.as_count()` |
| Latency P95 | `trace.<operation>.duration.by.resource_service.95percentile` |
| Consumer Lag | `kafka.consumer.lag` or Service Bus active messages |

## Threshold Guidelines

| Service Criticality | Warning | Critical |
|--------------------|---------|----------|
| User-facing (CIPUI) | 5% | 10% |
| API services | 10% | 25% |
| Background workers | 25% | 50% |
| Batch processing | 50% | 75% |

## Example: PDFWorker (from 2026-02-02 incident)

**Gap identified**: Queue depth alert (`hs-prod-pdfworker-queue > 2000`) fired 15-20min after deployment broke the service. Watchdog detected deployment issue but no monitor sent to Slack.

**Upstream monitor added**:
- Service: `hs-pdfworker`
- Operation: `listener.new_message`
- Thresholds: warn 10%, critical 50%
- Result: Would have alerted within 5min of deployment instead of waiting for queue backup

## Files Reference

```
~/code/healthsource/monitors/terraform/
├── environments/prod/
│   └── main.tf              # Config values
└── modules/datadog-hs-monitors-v2/
    ├── custom_application_monitors.tf  # Service-specific monitors
    ├── datadog_monitors.tf             # Generic APM monitors
    └── variables.tf                    # Variable definitions
```
