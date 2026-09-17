"""Read corporate panel status or open a requested desktop action."""

import json
import os
import shlex
import subprocess
import sys
from pathlib import Path


def output(*command: str) -> str:
    return subprocess.check_output(
        command,
        text=True,
        timeout=10,
        stderr=subprocess.PIPE,
        env={**os.environ, "LC_ALL": "C"},
    )


def failed_units() -> str:
    count = 0
    for scope in ([], ["--user"]):
        units = json.loads(
            output(
                "/usr/bin/systemctl", *scope, "--failed", "--output=json", "--no-pager"
            )
        )
        count += len(units)
    return f"FAIL {count}"


def apt_updates() -> str:
    lines = output("/usr/bin/apt", "list", "--upgradable").splitlines()
    count = sum("/" in line.split()[0] for line in lines if line.strip())
    return f"APT {count}"


def displays(root: Path = Path("/sys/class/drm")) -> str:
    connected = [
        path
        for path in root.glob("*/status")
        if "-eDP-" not in path.parent.name
        and "-LVDS-" not in path.parent.name
        and path.read_text().strip() == "connected"
    ]
    return f"EXT {len(connected)}"


def collect() -> dict:
    status = {
        "errors": "",
        "reboot": "REBOOT" if Path("/run/reboot-required").exists() else "",
    }
    for name, label, read in [
        ("displays", "EXT", displays),
        ("updates", "APT", apt_updates),
        ("failed", "FAIL", failed_units),
    ]:
        try:
            status[name] = read()
        except (OSError, ValueError, subprocess.SubprocessError, RuntimeError) as error:
            status[name] = f"{label} ?"
            status["errors"] += f"{label}: {error}\n"
    return status


def terminal(command: str) -> list[str]:
    shell = str(Path.home() / ".nix-profile/bin/zsh")
    pause = "; printf '\\nPress Enter to close'; read -r reply"
    return ["/snap/bin/ghostty", "-e", shell, "-lc", command + pause]


def action_command(action: str) -> list[str]:
    if action == "update":
        source = output(
            str(Path.home() / ".nix-profile/bin/chezmoi"), "source-path"
        ).strip()
        return terminal(f"cd -- {shlex.quote(source)} && just update")
    if action == "failed":
        return terminal("systemctl --failed; systemctl --user --failed")
    if action == "updates":
        return terminal("apt list --upgradable; snap refresh --list")
    if action == "reboot":
        return terminal("cat /run/reboot-required /run/reboot-required.pkgs")
    if action == "monitor":
        return terminal("htop")
    if action == "audio":
        return terminal("pulsemixer")
    if action == "mail":
        return ["/snap/bin/thunderbird"]
    if action == "displays":
        return ["/usr/bin/gnome-control-center", "display"]
    raise ValueError(f"Unknown panel action: {action}")


def main() -> None:
    if (Path.home() / ".config/dotfiles/role").read_text().strip() != "canonical":
        raise SystemExit("The panel requires the canonical role.")
    if sys.argv[1:] == ["status"]:
        print(json.dumps(collect()))
    elif len(sys.argv) == 3 and sys.argv[1] == "action":
        subprocess.Popen(action_command(sys.argv[2]), start_new_session=True)
    else:
        raise SystemExit("Use status or action NAME.")


if __name__ == "__main__":
    main()
