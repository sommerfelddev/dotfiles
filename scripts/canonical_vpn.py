"""Install and toggle a secondary Canonical VPN without tracking credentials."""

import argparse
import os
import shlex
import subprocess
import tempfile
import zipfile
from pathlib import Path

from scripts.canonical import require_canonical

NAME = "canonical-secondary"
REFERENCES = {"ca", "cert", "key", "tls-auth"}


def output(*args):
    return subprocess.check_output(["nmcli", *args], text=True).strip()


def run(command):
    subprocess.run(command, check=True)


def secondary_files(archive, endpoint, destination):
    with zipfile.ZipFile(archive) as source:
        names = source.namelist()
        candidates = [
            name
            for name in names
            if name.startswith(f"{endpoint}-")
            and name.endswith("@2.conf")
            and "/" not in name
        ]
        if len(candidates) != 1 or len(names) != len(set(names)):
            raise ValueError(
                "Archive must contain one secondary profile for the selected endpoint."
            )
        lines = source.read(candidates[0]).decode().splitlines()
        files, rendered, found = {}, [], set()
        for line in lines:
            words = shlex.split(line, comments=True)
            if words and words[0] in REFERENCES:
                directive, filename = words[:2]
                if (
                    directive in found
                    or Path(filename).name != filename
                    or filename in (".", "..")
                ):
                    raise ValueError(
                        "Credential references must be unique plain filenames."
                    )
                if directive in ("cert", "key") and not filename.endswith(
                    f"@2.{'crt' if directive == 'cert' else 'key'}"
                ):
                    raise ValueError(
                        "Refusing credentials that are not for the secondary identity."
                    )
                files[filename] = source.read(filename)
                path = (
                    str(destination / filename)
                    .replace("\\", "\\\\")
                    .replace('"', '\\"')
                )
                line = f'{directive} "{path}"' + (
                    " " + " ".join(words[2:]) if words[2:] else ""
                )
                found.add(directive)
            rendered.append(line)
        if found != REFERENCES:
            raise ValueError(
                "Profile must reference CA, secondary certificate/key, and TLS auth key."
            )
        files[f"{NAME}.conf"] = ("\n".join(rendered) + "\n").encode()
        return files


def write_credentials(destination, files):
    if destination.is_symlink() or destination.parent.is_symlink():
        raise ValueError("Credential directories must not be symlinks.")
    destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    if destination.exists():
        if any(
            (destination / name).is_symlink()
            or not (destination / name).is_file()
            or (destination / name).read_bytes() != data
            for name, data in files.items()
        ):
            raise ValueError("Existing credentials differ; no files were replaced.")
        destination.chmod(0o700)
        for name in files:
            (destination / name).chmod(0o600)
        return
    with tempfile.TemporaryDirectory(
        prefix=".vpn-", dir=destination.parent
    ) as temporary:
        staging = Path(temporary) / "credentials"
        staging.mkdir(mode=0o700)
        for name, data in files.items():
            path = staging / name
            path.write_bytes(data)
            path.chmod(0o600)
        staging.rename(destination)


def routing(mode):
    if mode not in ("full", "split"):
        raise ValueError("Routing mode must be full or split.")
    settings = []
    for family in ("ipv4", "ipv6"):
        settings.extend(
            [
                f"{family}.never-default",
                "no" if mode == "full" else "yes",
                f"{family}.dns-search",
                "~." if mode == "full" else "",
                f"{family}.dns-priority",
                "-50" if mode == "full" else "50",
            ]
        )
    return settings


def install(archive, endpoint):
    if NAME in output("-g", "NAME", "connection", "show").splitlines():
        raise ValueError(f"Profile {NAME} already exists; it was not replaced.")
    destination = Path.home() / ".sesame" / "canonical-secondary"
    files = secondary_files(archive, endpoint, destination)
    write_credentials(destination, files)
    run(
        [
            "sudo",
            "nmcli",
            "connection",
            "import",
            "type",
            "openvpn",
            "file",
            str(destination / f"{NAME}.conf"),
        ]
    )
    run(
        [
            "sudo",
            "nmcli",
            "connection",
            "modify",
            "id",
            NAME,
            "connection.autoconnect",
            "no",
            "connection.permissions",
            f"user:{os.environ['USER']}",
            *routing("split"),
        ]
    )
    print(f"Installed {NAME}, disconnected, with split routing selected.")


def up(mode):
    if NAME in output("-g", "NAME", "connection", "show", "--active").splitlines():
        raise ValueError(
            "Disconnect the secondary VPN before changing its routing mode."
        )
    run(["sudo", "nmcli", "connection", "modify", "id", NAME, *routing(mode)])
    run(["nmcli", "--ask", "connection", "up", "id", NAME])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)
    setup = commands.add_parser("install")
    setup.add_argument("archive", type=Path)
    setup.add_argument("--endpoint", choices=("uk", "us", "tw"), default="uk")
    connect = commands.add_parser("up")
    connect.add_argument("mode", choices=("full", "split"), default="split", nargs="?")
    commands.add_parser("down")
    args = parser.parse_args()
    require_canonical()
    if args.action == "install":
        install(args.archive, args.endpoint)
    elif args.action == "up":
        up(args.mode)
    else:
        run(["nmcli", "connection", "down", "id", NAME])


if __name__ == "__main__":
    try:
        main()
    except ValueError as error:
        raise SystemExit(str(error)) from None
    except (
        KeyError,
        OSError,
        zipfile.BadZipFile,
        subprocess.CalledProcessError,
    ):
        raise SystemExit(
            "VPN setup failed. Check the archive, installed OpenVPN plug-in, and profile state."
        ) from None
