#!/usr/bin/env python3
"""Notification picker.

Lists currently-visible mako notifications. Selecting one copies its
"summary\\nbody" to the clipboard and dismisses it via `makoctl dismiss
-n <id>`. The picker re-opens after each selection so multiple
notifications can be processed in one go; Esc closes it.
"""

from __future__ import annotations

import re
import subprocess
from pathlib import Path
from typing import Any

RECORD_RE = re.compile(r"^Notification (\d+):\s?(.*)$")
FIELD_RE = re.compile(r"^  ([A-Za-z][A-Za-z ]*?):\s*(.*)$")


def list_notifications() -> list[dict[str, Any]]:
    try:
        out = subprocess.run(
            ["makoctl", "list"], capture_output=True, text=True, check=True
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []
    notifs: list[dict[str, Any]] = []
    cur: dict[str, Any] | None = None
    last_field: str | None = None
    for line in out.splitlines():
        m = RECORD_RE.match(line)
        if m:
            if cur is not None:
                notifs.append(cur)
            cur = {"id": int(m.group(1)), "summary": m.group(2).strip()}
            last_field = "summary"
            continue
        if cur is None:
            continue
        m = FIELD_RE.match(line)
        if m:
            key = m.group(1).strip().lower().replace(" ", "_")
            cur[key] = m.group(2)
            last_field = key
            continue
        if last_field == "body" and line.startswith("        "):
            cur["body"] = (str(cur.get("body", "")) + " " + line.strip()).strip()
    if cur is not None:
        notifs.append(cur)
    return notifs


def fmt_line(n: dict[str, Any]) -> str:
    app = (str(n.get("app_name") or "?")).strip() or "?"
    summary = str(n.get("summary") or "").strip()
    body = str(n.get("body") or "").strip()
    text = summary if not body else f"{summary} — {body}"
    text = text.replace("\t", " ").replace("\r", " ")
    return f"[{app}] {text}\t#{n['id']}"


def parse_selection(line: str) -> int | None:
    m = re.search(r"\t#(\d+)\s*$", line)
    return int(m.group(1)) if m else None


def run_wofi(input_text: str, lines: int) -> str:
    style = Path.home() / ".config/wofi/style.css"
    cmd = [
        "wofi",
        "--dmenu",
        "--hide-search",
        "--prompt",
        "Notifications",
        "--lines",
        str(lines),
    ]
    if style.exists():
        cmd += ["--style", str(style)]
    proc = subprocess.run(
        cmd, input=input_text, text=True, capture_output=True, check=False
    )
    return proc.stdout.strip()


def main() -> None:
    while True:
        notifs = list_notifications()
        if not notifs:
            _ = run_wofi("(no notifications)\n", 1)
            return

        lines_text = "\n".join(fmt_line(n) for n in notifs) + "\n"
        sel = run_wofi(lines_text, min(len(notifs), 15))
        if not sel or sel.startswith("(no "):
            return

        nid = parse_selection(sel)
        if nid is None:
            return
        notif = next((n for n in notifs if n["id"] == nid), None)
        if notif is None:
            return

        summary = str(notif.get("summary") or "").strip()
        body = str(notif.get("body") or "").strip()
        clip_text = f"{summary}\n{body}".strip()
        _ = subprocess.run(["wl-copy"], input=clip_text, text=True, check=False)
        _ = subprocess.run(["makoctl", "dismiss", "-n", str(nid)], check=False)


if __name__ == "__main__":
    main()
