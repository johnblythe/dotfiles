#!/usr/bin/env python3
"""Scan Claude Code session transcripts and produce a morning context refresh."""

import json
import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

PROJECTS_DIR = Path.home() / ".claude" / "projects"
# default: sessions from last 24h
HOURS = int(sys.argv[1]) if len(sys.argv) > 1 else 24
CUTOFF = datetime.now() - timedelta(hours=HOURS)
MIN_LINES = 8  # skip trivial/empty sessions


def extract_session(fpath: Path, proj_short: str) -> dict | None:
    mtime = datetime.fromtimestamp(fpath.stat().st_mtime)
    if mtime < CUTOFF:
        return None

    lines = sum(1 for _ in open(fpath))
    if lines < MIN_LINES:
        return None

    title = None
    branch = None
    first_user_msg = None
    last_user_msg = None
    user_msgs = []
    asst_texts = []
    user_msg_count = 0
    cwd = None

    with open(fpath) as f:
        for line in f:
            try:
                obj = json.loads(line)
            except Exception:
                continue

            if obj.get("type") == "custom-title" and not title:
                title = obj.get("customTitle")

            if not branch:
                branch = obj.get("gitBranch")

            if not cwd:
                cwd = obj.get("cwd")

            if obj.get("type") == "user":
                msg = obj.get("message", {})
                if isinstance(msg, dict):
                    content = msg.get("content", "")
                    if (
                        isinstance(content, str)
                        and not content.strip().startswith("<")
                        and len(content.strip()) > 5
                    ):
                        user_msg_count += 1
                        clean = content.strip()[:300]
                        user_msgs.append(clean)
                        if not first_user_msg:
                            first_user_msg = clean
                        last_user_msg = clean

            if obj.get("type") == "assistant":
                msg = obj.get("message", {})
                if isinstance(msg, dict):
                    content = msg.get("content", "")
                    if isinstance(content, list):
                        for c in content:
                            if isinstance(c, dict) and c.get("type") == "text":
                                t = c["text"].strip()
                                if t and len(t) > 10:
                                    asst_texts.append(t[:300])

    if user_msg_count == 0:
        return None

    return {
        "project": proj_short,
        "title": title or "(untitled)",
        "branch": branch or "?",
        "cwd": cwd,
        "mtime": mtime.strftime("%Y-%m-%d %H:%M"),
        "user_msg_count": user_msg_count,
        "first_user_msg": first_user_msg,
        "last_user_msg": last_user_msg,
        "user_msgs_sample": user_msgs[:5],
        "last_asst_text": asst_texts[-1] if asst_texts else None,
        "session_id": fpath.stem,
        "lines": lines,
    }


def main():
    sessions = []
    for proj_dir in sorted(PROJECTS_DIR.iterdir()):
        if not proj_dir.is_dir():
            continue
        proj_short = (
            proj_dir.name.replace("-Users-john-blythe-code-", "")
            .replace("-Users-john-blythe-", "~/")
            .replace("-", "/")
        )
        for fname in proj_dir.iterdir():
            if not fname.suffix == ".jsonl":
                continue
            if "subagents" in str(fname):
                continue
            result = extract_session(fname, proj_short)
            if result:
                sessions.append(result)

    sessions.sort(key=lambda s: s["mtime"], reverse=True)

    # Output as JSON for Claude to consume
    print(json.dumps(sessions, indent=2))


if __name__ == "__main__":
    main()
