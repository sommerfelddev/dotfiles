"""Install declared corporate packages without removing existing packages."""

import argparse
import json
import os
import platform
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def packages(source: str) -> list[str]:
    return [
        line.strip()
        for line in (ROOT / "meta/canonical" / f"{source}.txt").read_text().splitlines()
        if line.strip() and not line.startswith("#")
    ]


def snap_install_commands() -> list[list[str]]:
    return [
        ["sudo", "snap", "install", name, "--channel=stable"]
        + (["--classic"] if name == "ghostty" else [])
        for name in packages("snap")
    ]


def flatpak_install_commands() -> list[list[str]]:
    return [
        [
            "flatpak",
            "remote-add",
            "--user",
            "--if-not-exists",
            "flathub",
            "https://flathub.org/repo/flathub.flatpakrepo",
        ],
        [
            "flatpak",
            "install",
            "--user",
            "--assumeyes",
            "flathub",
            *packages("flatpak"),
        ],
    ]


def update_commands() -> list[list[str]]:
    # An untargeted refresh respects Snap holds. Explicit targets override them.
    return [
        ["sudo", "apt-get", "update"],
        ["sudo", "apt-get", "upgrade"],
        ["sudo", "snap", "refresh"],
    ]


def require_canonical() -> None:
    data = json.loads(
        subprocess.check_output(["chezmoi", "data", "-S", str(ROOT)], text=True)
    )
    if data.get("machineRole") != "canonical":
        raise SystemExit("This command requires machineRole=canonical.")
    if platform.freedesktop_os_release().get("ID") != "ubuntu":
        raise SystemExit("This command requires Ubuntu.")


def install() -> None:
    subprocess.run(["sudo", "apt-get", "update"], check=True)
    subprocess.run(["sudo", "apt-get", "install", *packages("apt")], check=True)
    for command in snap_install_commands():
        if subprocess.run(
            ["snap", "list", command[3]],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode:
            subprocess.run(command, check=True)
    for command in flatpak_install_commands():
        subprocess.run(command, check=True)


def require_lab() -> None:
    marker = Path("/etc/canonical-lab")
    if not marker.is_file() or marker.stat().st_uid != 0:
        raise SystemExit("This command requires a root-owned lab marker.")
    if subprocess.run(
        ["systemd-detect-virt", "--vm", "--quiet"], check=False
    ).returncode:
        raise SystemExit("This command requires a virtual machine.")


def check(lab: bool = False) -> None:
    if lab:
        require_lab()
        print("UNTESTED: company provisioning, authd, and Landscape registration.")
    commands = [
        ["lsb_release", "-ds"],
        *[
            ["systemctl", "is-active", unit]
            for unit in ["display-manager", "snapd", "apparmor"]
        ],
        ["nix", "store", "ping", "--store", "daemon"],
        *([] if lab else [["landscape-config", "--actively-registered"]]),
        ["snap", "connections", "thunderbird"],
        ["snap", "list", *packages("snap")],
        ["gnome-extensions", "list", "--enabled"],
        ["flatpak", "list", "--user", "--app"],
        *[["flatpak", "info", "--user", app] for app in packages("flatpak")],
        ["getent", "passwd", str(os.getuid())],
        ["getsubids", os.environ.get("USER", "")],
        ["getsubids", "-g", os.environ.get("USER", "")],
    ]
    failed = False
    for command in commands:
        print("\n> " + " ".join(command), flush=True)
        try:
            failed |= subprocess.run(command, check=False).returncode != 0
        except FileNotFoundError:
            print(f"Missing: {command[0]}")
            failed = True
    if failed:
        raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "action",
        choices=[
            "install",
            "update",
            "flatpak-update",
            "extensions",
            "check",
            "lab-check",
        ],
    )
    args = parser.parse_args()
    require_canonical()
    if args.action == "install":
        install()
    elif args.action in {"check", "lab-check"}:
        check(lab=args.action == "lab-check")
    else:
        commands = update_commands()
        if args.action == "flatpak-update":
            commands = [
                ["flatpak", "update", "--user", "--assumeyes", *packages("flatpak")]
            ]
        elif args.action == "extensions":
            commands = [["gext", "--filesystem", "install", *packages("extensions")]]
        for command in commands:
            subprocess.run(command, check=True)


if __name__ == "__main__":
    main()
