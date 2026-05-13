#!/usr/bin/env python3
"""Notification history picker.

Lists pending mako notifications (visible bubbles + history). Entries
dismissed via this picker are hidden so the list shrinks as you process it.

Keys:
  Enter   copy "summary\\nbody" to the clipboard and dismiss the entry
  Esc     cancel

State file: $XDG_RUNTIME_DIR/mako-dismissed (one id per line, per-session).
"""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path
from typing import Any

STATE = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "mako-dismissed"


RECORD_RE = re.compile(r"^Notification (\d+):\s?(.*)$")
FIELD_RE = re.compile(r"^  ([A-Za-z][A-Za-z ]*?):\s*(.*)$")


def _run_makoctl(subcmd: str) -> str:
    try:
        return subprocess.run(
            ["makoctl", subcmd], capture_output=True, text=True, check=True
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def _parse_block(out: str) -> list[dict[str, Any]]:
    """Parse mako's text dump.

    Format (per notification):
        Notification N: <summary>
          App name: <app>
          [Category: <cat>]
          [Body: <body line>]
          [        <body cont>]
          Urgency: <urgency>
    """
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


def parse_history(dismissed: set[str]) -> list[dict[str, Any]]:
    """Return visible + history notifications, deduped by id, visible first.

    Entries whose id is in `dismissed` are filtered out.
    """
    visible = _parse_block(_run_makoctl("list"))
    history = _parse_block(_run_makoctl("history"))
    seen: set[int] = set()
    out: list[dict[str, Any]] = []
    for n in visible + history:
        nid = int(n["id"])
        if nid in seen or str(nid) in dismissed:
            continue
        seen.add(nid)
        out.append(n)
    return out


def load_dismissed() -> set[str]:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.touch(exist_ok=True)
    return {x for x in STATE.read_text().split() if x}


def save_dismissed(ids: set[str]) -> None:
    payload = "\n".join(sorted(ids, key=lambda s: int(s) if s.isdigit() else 0))
    _ = STATE.write_text(payload + ("\n" if ids else ""))


def add_dismissed(nid: int) -> None:
    ids = load_dismissed()
    ids.add(str(nid))
    save_dismissed(ids)


def fmt_line(n: dict[str, Any]) -> str:
    app = (str(n.get("app_name") or "?")).strip() or "?"
    summary = str(n.get("summary") or "").strip()
    body = str(n.get("body") or "").strip()
    text = summary if not body else f"{summary} — {body}"
    text = text.replace("\t", " ").replace("\r", " ")
    # Trailing id sentinel for parsing on selection.
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
    dismissed = load_dismissed()
    notifs = parse_history(dismissed)

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
    add_dismissed(nid)


if __name__ == "__main__":
    main()
