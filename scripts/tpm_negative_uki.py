"""Prepare a UKI that retains NvPCR approval but lacks root-unlock approval."""

import json
import os
import subprocess
import sys
from pathlib import Path

import pefile

from scripts.tpm_nvpcr import PUBLIC_KEY, read_pe_sections, verify_pcr_signatures


def remove_root_approval(source: Path, destination: Path, public_key: bytes) -> None:
    if destination.exists():
        raise ValueError("Refusing to replace an existing test image")
    original = read_pe_sections(source)
    verify_pcr_signatures(original, public_key)
    with destination.open("xb") as output:
        output.write(source.read_bytes())
    try:
        subprocess.run(
            ["sbattach", "--remove", str(destination)], check=True, capture_output=True
        )
        pe = pefile.PE(str(destination), fast_load=True)
        sections = [s for s in pe.sections if s.Name.rstrip(b"\0") == b".pcrsig"]
        if len(sections) != 1:
            raise ValueError("Expected one .pcrsig section")
        section = sections[0]
        length = min(section.Misc_VirtualSize, section.SizeOfRawData)
        offset = section.PointerToRawData
        image = bytearray(destination.read_bytes())
        old = bytes(image[offset : offset + length])
        if old.count(b"luks-root") != 1:
            raise ValueError("Expected exactly one luks-root approval")
        new = old.replace(b"luks-root", b"deny-root")
        policies = json.loads(new.decode().rstrip("\0"))
        if any(item.get("ref") == "luks-root" for item in policies.get("sha256", [])):
            raise ValueError("Root approval remains in test image")
        image[offset : offset + length] = new
        destination.write_bytes(image)
        changed = read_pe_sections(destination)
        if any(
            original.get(name) != changed.get(name)
            for name in original
            if name != ".pcrsig"
        ):
            raise ValueError("Test image changed a measured section")
        verify_pcr_signatures(changed, public_key, refs=("initrd",))
    except Exception:
        destination.unlink()
        raise


def main() -> None:
    if len(sys.argv) != 3:
        raise ValueError("Usage: tpm_negative_uki.py SOURCE DESTINATION")
    if os.geteuid() != 0 or Path("/etc/hostname").read_text().strip() != "halley2":
        raise ValueError("Run as root on Halley2")
    remove_root_approval(Path(sys.argv[1]), Path(sys.argv[2]), PUBLIC_KEY.read_bytes())
    print(f"prepared: {sys.argv[2]} (sign with Secure Boot key before testing)")


if __name__ == "__main__":
    try:
        main()
    except (OSError, TypeError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"Negative UKI preparation failed: {exc}", file=sys.stderr)
        sys.exit(1)
