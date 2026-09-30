"""Read-only checks for Halley2's signed NvPCR UKIs."""

import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

BOOT = Path("/boot/EFI/Linux")
PUBLIC_KEY = Path("/etc/systemd/tpm2-pcr-public-key.pem")
SB_CERT = Path("/var/lib/sbctl/keys/db/db.pem")
IMAGES = (
    "arch-linux-hardened.efi",
    "arch-linux-hardened-fallback.efi",
    "arch-linux-lts.efi",
    "arch-linux-lts-fallback.efi",
)
MEASUREMENT_OPTIONS = (
    "tpm2-device=auto",
    "tpm2-measure-pcr=15",
    "tpm2-measure-keyslot-nvpcr=cryptsetup",
)
INITRD_UNITS = (
    "systemd-tpm2-setup-early.service",
    "systemd-pcrnvdone.service",
    "systemd-pcrextend.socket",
    "systemd-pcrextend@.service",
)


def run(*command: str) -> str:
    result = subprocess.run(command, capture_output=True, text=True, check=True)
    return result.stdout


def check_sections(sections: dict, public_key: bytes) -> None:
    public = sections.get(".pcrpkey")
    if (
        not isinstance(public, dict)
        or public.get("sha256") != hashlib.sha256(public_key).hexdigest()
    ):
        raise ValueError("UKI does not embed the expected PCR public key")

    signature = sections.get(".pcrsig")
    if not isinstance(signature, dict) or not isinstance(signature.get("text"), str):
        raise TypeError("UKI has no readable PCR signatures")
    policies = json.loads(signature["text"])
    if not isinstance(policies, dict) or not any(
        isinstance(item, dict)
        and item.get("pcrs") == [11]
        and item.get("ref") == "initrd"
        and isinstance(item.get("sig"), str)
        and bool(item["sig"])
        for item in policies.get("sha256", [])
    ):
        raise ValueError("UKI has no signed initrd PCR 11 policy")

    cmdline = sections.get(".cmdline")
    if not isinstance(cmdline, dict) or not isinstance(cmdline.get("text"), str):
        raise TypeError("UKI has no kernel command line")
    args = cmdline["text"].split()
    roots = [arg.split("=", 2)[1] for arg in args if arg.startswith("rd.luks.name=")]
    if len(roots) != 1:
        raise ValueError("UKI must specify exactly one LUKS root device")
    options = [
        arg.removeprefix("rd.luks.options=")
        for arg in args
        if arg.startswith("rd.luks.options=")
    ]
    if len(options) != 1 or not options[0].startswith(roots[0] + "="):
        raise ValueError("Root measurement options have the wrong LUKS UUID")
    selected = options[0].split("=", 1)[1].split(",")
    if not all(option in selected for option in MEASUREMENT_OPTIONS):
        raise ValueError("Root measurement or TPM unlock option is missing")


def check_initrd_listing(listing: str) -> None:
    members = {line.strip().lstrip("./") for line in listing.splitlines()}
    for unit in INITRD_UNITS:
        if f"usr/lib/systemd/system/{unit}" not in members:
            raise ValueError(f"UKI initrd lacks {unit}")


def check_image(path: Path, public_key: bytes) -> None:
    sections = json.loads(
        run(
            "ukify",
            "--json=short",
            "--section=.pcrpkey:binary",
            "--section=.pcrsig:text",
            "--section=.cmdline:text",
            "inspect",
            str(path),
        )
    )
    if not isinstance(sections, dict) or "_profiles" in sections:
        raise ValueError(f"Unsupported multi-profile UKI: {path}")
    check_sections(sections, public_key)
    check_initrd_listing(run("lsinitcpio", "--list", str(path)))
    run("sbverify", "--cert", str(SB_CERT), str(path))
    print(f"verified: {path}")


def check_boot() -> None:
    active = Path("/proc/cmdline").read_text()
    if not all(option in active for option in MEASUREMENT_OPTIONS):
        raise ValueError("Current boot did not use the NvPCR root options")
    nvpcrs = run("systemd-analyze", "nvpcrs", "--no-pager")
    for name in ("cryptsetup", "hardware", "login", "verity"):
        if name not in nvpcrs:
            raise ValueError(f"NvPCR {name} is not available")
    run(
        "/usr/lib/systemd/systemd-pcrlock",
        "--strict=yes",
        "--pcr=7",
        "--location=770",
        "predict",
    )
    failed = run("systemctl", "--failed", "--no-legend", "--no-pager")
    if failed.strip():
        raise ValueError("Systemd has failed units; inspect systemctl --failed")
    print(
        "verified: current boot options, NvPCR availability, and strict PCR 7 prediction"
    )


def main() -> int:
    if os.geteuid() != 0 or Path("/etc/hostname").read_text().strip() != "halley2":
        raise ValueError("Run as root on Halley2")
    public_key = PUBLIC_KEY.read_bytes()
    if not public_key:
        raise ValueError("Missing PCR public key")
    paths = [Path(arg) for arg in sys.argv[1:]] or [BOOT / name for name in IMAGES]
    for path in paths:
        check_image(path, public_key)
    if len(sys.argv) == 1:
        check_boot()
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, TypeError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"NvPCR check failed: {exc}", file=sys.stderr)
        sys.exit(1)
