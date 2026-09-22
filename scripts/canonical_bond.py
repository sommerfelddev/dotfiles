"""Prepare inactive NetworkManager bond profiles and local recovery commands."""

import configparser
import io
import json
import os
import shlex
import shutil
import subprocess
import sys
import uuid
from pathlib import Path

STATE = Path("/var/lib/dotfiles/bond0")
BOND_UUID = "88919b61-3a22-4cb6-9485-440725990cea"


def nmcli(*args, input=None):
    return subprocess.check_output(["nmcli", *args], input=input, text=True).strip()


def keyfile(text):
    parser = configparser.ConfigParser(interpolation=None, strict=True)
    parser.optionxform = lambda optionstr: optionstr
    parser.read_string(text)
    return parser


def bond_profile():
    return nmcli(
        "--offline",
        "connection",
        "add",
        "type",
        "bond",
        "ifname",
        "bond0",
        "con-name",
        "dotfiles-bond0",
        "connection.uuid",
        BOND_UUID,
        "connection.autoconnect",
        "no",
        "connection.autoconnect-ports",
        "1",
        "bond.options",
        "mode=active-backup,miimon=1000,fail_over_mac=active,primary_reselect=always",
        "ipv4.method",
        "auto",
        "ipv4.dhcp-client-id",
        "duid",
        "ipv4.dhcp-iaid",
        "1",
        "ipv6.method",
        "auto",
        "ipv6.dhcp-duid",
        "stable-uuid",
        "ipv6.dhcp-iaid",
        "1",
        "connection.stable-id",
        "dotfiles-bond0",
    )


def port_profile(source, kind, identity, priority):
    if kind not in ("wifi", "ethernet", "802-11-wireless", "802-3-ethernet"):
        raise ValueError(f"Not an Ethernet or Wi-Fi profile: {kind}")
    config = keyfile(source)
    if config.get("connection", "secondaries", fallback=""):
        raise ValueError(
            "A profile with automatic VPN connections needs separate review."
        )
    for section in ("ipv4", "ipv6", "proxy"):
        config.remove_section(section)
    data = io.StringIO()
    config.write(data, space_around_delimiters=False)
    setting = (
        "802-11-wireless" if kind in ("wifi", "802-11-wireless") else "802-3-ethernet"
    )
    return nmcli(
        "--offline",
        "connection",
        "modify",
        "connection.id",
        f"dotfiles-bond-{identity}",
        "connection.uuid",
        identity,
        "connection.autoconnect",
        "no",
        "connection.controller",
        BOND_UUID,
        "connection.port-type",
        "bond",
        "connection.secondaries",
        "",
        "bond-port.prio",
        str(priority),
        f"{setting}.cloned-mac-address",
        "permanent",
        input=data.getvalue(),
    )


def profile_source(identity):
    for directory in ("/etc", "/run", "/usr/lib"):
        for path in Path(directory, "NetworkManager/system-connections").glob("*"):
            if path.is_file():
                text = path.read_text()
                if keyfile(text).get("connection", "uuid", fallback="") == identity:
                    return text
    raise ValueError(f"No saved NetworkManager keyfile for {identity}")


def prepare_port(name):
    identity = nmcli("-g", "connection.uuid", "connection", "show", name)
    source = profile_source(identity)
    config = keyfile(source)
    kind = config["connection"]["type"]
    interface = config.get("connection", "interface-name", fallback="") or nmcli(
        "-g", "GENERAL.DEVICES", "con", "show", "uuid", identity
    )
    if "/" in interface or not Path("/sys/class/net", interface, "device").exists():
        raise ValueError(f"Profile needs one physical interface present: {name}")
    config["connection"]["interface-name"] = interface
    if config.get("connection", "master", fallback="") or config.get(
        "connection", "controller", fallback=""
    ):
        raise ValueError(f"Profile already belongs to a controller: {name}")
    wireless = kind in ("wifi", "802-11-wireless")
    if wireless and not config.get("wifi-security", "psk", fallback=""):
        raise ValueError(
            "Wi-Fi needs a system-saved PSK for unattended failover; no profile was changed."
        )
    clone = str(uuid.uuid4())
    data = io.StringIO()
    config.write(data, space_around_delimiters=False)
    return {
        "original": identity,
        "autoconnect": nmcli(
            "-g", "connection.autoconnect", "con", "show", "uuid", identity
        ),
        "uuid": clone,
        "interface": interface,
        "profile": port_profile(data.getvalue(), kind, clone, 0 if wireless else 100),
    }


def shell_command(*args):
    return shlex.join(str(arg) for arg in args)


def recovery_commands(ports):
    commands = ["#!/bin/sh", "set -u"]
    commands.append("systemctl stop dotfiles-bond-rollback.timer || true")
    for identity in [BOND_UUID, *(port["uuid"] for port in ports)]:
        commands.append(
            shell_command(
                "nmcli", "con", "mod", "uuid", identity, "connection.autoconnect", "no"
            )
            + " || true"
        )
    for identity in [BOND_UUID, *(port["uuid"] for port in ports)]:
        commands.append(
            shell_command("nmcli", "con", "delete", "uuid", identity) + " || true"
        )
        commands.append(
            shell_command(
                "rm",
                "-f",
                f"/etc/NetworkManager/system-connections/dotfiles-{identity}.nmconnection",
            )
        )
    for port in ports:
        commands.append(
            shell_command(
                "nmcli",
                "con",
                "mod",
                "uuid",
                port["original"],
                "connection.autoconnect",
                port["autoconnect"],
            )
        )
    active = set(nmcli("-g", "UUID", "con", "show", "--active").splitlines())
    for port in ports:
        if port["original"] in active:
            commands.append(
                shell_command(
                    "nmcli", "--wait", "0", "con", "up", "uuid", port["original"]
                )
            )
    return "\n".join(commands) + "\n"


def activation_commands(ports, active=()):
    commands = ["#!/bin/sh", "set -eu"]
    commands.append(
        shell_command(
            "systemd-run",
            "--collect",
            "--unit=dotfiles-bond-rollback",
            "--on-active=5m",
            "/bin/sh",
            STATE / "rollback.sh",
        )
    )
    commands.append("trap 'sh /var/lib/dotfiles/bond0/rollback.sh' EXIT")
    commands.append(
        "install -m 600 /var/lib/dotfiles/bond0/*.nmconnection /etc/NetworkManager/system-connections/"
    )
    for identity in [BOND_UUID, *(port["uuid"] for port in ports)]:
        commands.append(
            shell_command(
                "nmcli",
                "con",
                "load",
                f"/etc/NetworkManager/system-connections/dotfiles-{identity}.nmconnection",
            )
        )
    for port in ports:
        commands.append(
            shell_command(
                "nmcli",
                "con",
                "mod",
                "uuid",
                port["original"],
                "connection.autoconnect",
                "no",
            )
        )
        if port["original"] in active:
            commands.append(
                shell_command("nmcli", "con", "down", "uuid", port["original"])
            )
    for identity in [*(port["uuid"] for port in ports), BOND_UUID]:
        commands.append(
            shell_command(
                "nmcli", "con", "mod", "uuid", identity, "connection.autoconnect", "yes"
            )
        )
    commands.append(
        shell_command("nmcli", "--wait", "0", "con", "up", "uuid", BOND_UUID)
    )
    commands.append("trap - EXIT")
    commands.append(
        "echo 'Rollback is due in five minutes. Test locally, then run just canonical-bond-keep.'"
    )
    return "\n".join(commands) + "\n"


def prepare(names):
    if os.geteuid() != 0:
        raise ValueError("Run preparation through the sudo recipe.")
    if STATE.exists():
        raise ValueError(
            f"Preparation already exists at {STATE}; do not overwrite recovery data."
        )
    if (
        BOND_UUID in nmcli("-g", "UUID", "con", "show").splitlines()
        or Path("/sys/class/net/bond0").exists()
    ):
        raise ValueError("A bond already exists; stop before replacing it.")
    ports = [prepare_port(name) for name in names]
    active = set(nmcli("-g", "UUID", "con", "show", "--active").splitlines())
    if len({port["original"] for port in ports}) != len(ports):
        raise ValueError("Each source profile must be unique.")
    if len({port["interface"] for port in ports}) != len(ports):
        raise ValueError("Select only one profile per physical interface.")
    profiles = {BOND_UUID: bond_profile(), **{p["uuid"]: p["profile"] for p in ports}}
    scripts = {
        "activate.sh": activation_commands(ports, active),
        "rollback.sh": recovery_commands(ports),
    }
    os.umask(0o077)
    STATE.mkdir(parents=True, mode=0o700)
    try:
        for identity, text in profiles.items():
            (STATE / f"dotfiles-{identity}.nmconnection").write_text(text + "\n")
        for name, text in scripts.items():
            (STATE / name).write_text(text)
        (STATE / "profiles.json").write_text(
            json.dumps(
                [{k: v for k, v in p.items() if k != "profile"} for p in ports],
                indent=2,
            )
            + "\n"
        )
    except Exception:
        shutil.rmtree(STATE)
        raise
    print(f"Prepared inactive profiles in {STATE}. No live connection was changed.")


if __name__ == "__main__":
    if not sys.argv[1:]:
        sys.exit("Supply the Ethernet and Wi-Fi connection profile names.")
    try:
        prepare(sys.argv[1:])
    except (ValueError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
