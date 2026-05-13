#!/usr/bin/env python3
"""Notification history picker.

Lists mako's history annotated with pending/seen status. Default action
re-emits the notification (so the bubble pops again) and marks it seen.
Alt-c copies "summary\\nbody" to the clipboard via wl-copy.
Alt-d marks the entry seen without re-showing.

State file: $XDG_RUNTIME_DIR/mako-dismissed (one id per line, per-session).
"""

from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path

STATE = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "mako-dismissed"
RECORD_RE = re.compile(r"^Notification (\d+):\s*$")
FIELD_RE = re.compile(r"^  ([A-Za-z][A-Za-z ]*?):\s*(.*)$")


def _run_makoctl(subcmd: str) -> str:
    try:
        return subprocess.run(
            ["makoctl", subcmd], capture_output=True, text=True, check=True
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        return ""


def _parse_block(out: str) -> list[dict]:
    notifs: list[dict] = []
    cur: dict | None = None
    last_field: str | None = None
    for line in out.splitlines():
        m = RECORD_RE.match(line)
        if m:
            if cur is not None:
                notifs.append(cur)
            cur = {"id": int(m.group(1))}
            last_field = None
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
            cur["body"] = (cur.get("body", "") + " " + line.strip()).strip()
    if cur is not None:
        notifs.append(cur)
    return notifs


def parse_history() -> list[dict]:
    """Return visible + history notifications, deduped by id, visible first."""
    visible = _parse_block(_run_makoctl("list"))
    history = _parse_block(_run_makoctl("history"))
    seen: set[int] = set()
    out: list[dict] = []
    for n in visible + history:
        if n["id"] in seen:
            continue
        seen.add(n["id"])
        out.append(n)
    return out


def load_dismissed() -> set[str]:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.touch(exist_ok=True)
    return {x for x in STATE.read_text().split() if x}


def save_dismissed(ids: set[str]) -> None:
    payload = "\n".join(sorted(ids, key=lambda s: int(s) if s.isdigit() else 0))
    STATE.write_text(payload + ("\n" if ids else ""))


def add_dismissed(nid: int) -> None:
    ids = load_dismissed()
    ids.add(str(nid))
    save_dismissed(ids)


def fmt_line(n: dict, dismissed: set[str]) -> str:
    pending = str(n["id"]) not in dismissed
    mark = "●" if pending else " "
    app = (n.get("app_name") or "?").strip() or "?"
    summary = (n.get("summary") or "").strip()
    body = (n.get("body") or "").strip()
    text = summary if not body else f"{summary} — {body}"
    text = text.replace("\t", " ").replace("\r", " ")
    # Trailing id sentinel for parsing on selection.
    return f"[{mark}] [{app}] {text}\t#{n['id']}"


def parse_selection(line: str) -> int | None:
    m = re.search(r"\t#(\d+)\s*$", line)
    return int(m.group(1)) if m else None


def run_wofi(input_text: str, lines: int) -> tuple[int, str]:
    style = Path.home() / ".config/wofi/style.css"
    cmd = [
        "wofi",
        "--dmenu",
        "--hide-search",
        "--prompt", "Notifications",
        "--define", "key_custom_0=Alt-c",
        "--define", "key_custom_1=Alt-d",
        "--lines", str(lines),
    ]
    if style.exists():
        cmd += ["--style", str(style)]
    proc = subprocess.run(
        cmd, input=input_text, text=True, capture_output=True,
    )
    return proc.returncode, proc.stdout.strip()


def main() -> None:
    notifs = parse_history()
    dismissed = load_dismissed()

    if not notifs:
        run_wofi("(no notifications)\n", 1)
        return

    lines_text = "\n".join(fmt_line(n, dismissed) for n in notifs) + "\n"
    rc, sel = run_wofi(lines_text, min(len(notifs), 15))

    if not sel or sel.startswith("(no "):
        return

    nid = parse_selection(sel)
    if nid is None:
        return
    notif = next((n for n in notifs if n["id"] == nid), None)
    if notif is None:
        return

    summary = (notif.get("summary") or "").strip()
    body = (notif.get("body") or "").strip()
    app = (notif.get("app_name") or "").strip()
    clip_text = f"{summary}\n{body}".strip()

    if rc == 10:  # Alt-c → copy
        subprocess.run(["wl-copy"], input=clip_text, text=True)
    elif rc == 11:  # Alt-d → mark seen, no re-show
        add_dismissed(nid)
    elif rc == 0:  # Enter → re-emit + mark seen
        cmd = ["notify-send"]
        if app:
            cmd += ["-a", app]
        cmd.append(summary or "(no summary)")
        if body:
            cmd.append(body)
        subprocess.run(cmd)
        add_dismissed(nid)


if __name__ == "__main__":
    main()
