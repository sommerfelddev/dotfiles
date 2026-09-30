"""Audit the LUKS token used for automatic root unlock on Halley2."""

import base64
import binascii
import json
import os
import subprocess
import sys
from pathlib import Path

from cryptography.hazmat.primitives import serialization

from scripts.tpm_nvpcr import PUBLIC_KEY

DEVICE = "/dev/nvme0n1p2"


def decoded(value: object, field: str) -> bytes:
    if not isinstance(value, str):
        raise TypeError(f"Missing {field}")
    try:
        result = base64.b64decode(value, validate=True)
    except (ValueError, binascii.Error) as exc:
        raise ValueError(f"Invalid {field}") from exc
    if not result:
        raise ValueError(f"Empty {field}")
    return result


def check_header(
    header: dict, public_key: bytes, *, trial: bool = False
) -> tuple[str, str]:
    tokens = header.get("tokens", {})
    slots = header.get("keyslots", {})
    if not isinstance(tokens, dict) or len(tokens) != 1:
        raise ValueError("Expected exactly one automatic-unlock token")
    if not isinstance(slots, dict) or "0" not in slots:
        raise ValueError("Passphrase keyslot 0 is missing")
    token_id, token = next(iter(tokens.items()))
    if not isinstance(token, dict) or token.get("type") != "systemd-tpm2":
        raise ValueError("Expected one systemd TPM2 token")
    assigned = token.get("keyslots")
    if not isinstance(assigned, list) or len(assigned) != 1:
        raise ValueError("TPM token must name exactly one keyslot")
    slot = assigned[0]
    if slot == "0" or slot not in slots:
        raise ValueError("TPM token has no separate live keyslot")
    if not trial and set(slots) != {"0", slot}:
        raise ValueError("Unexpected extra keyslot after migration")

    if token.get("tpm2-pcrs") != [] or token.get("tpm2-pcr-bank") != "sha256":
        raise ValueError("Unexpected direct PCR binding or PCR bank")
    if token.get("tpm2_pcrlock") is not True:
        raise ValueError("TPM token does not require pcrlock")
    decoded(token.get("tpm2_pcrlock_nv"), "pcrlock NV reference")
    if (
        token.get("tpm2_pubkey_pcrs") != [11]
        or token.get("tpm2_pubkey_ref") != "luks-root"
    ):
        raise ValueError(
            "TPM token does not require the signed luks-root PCR 11 policy"
        )
    embedded = serialization.load_pem_public_key(
        decoded(token.get("tpm2_pubkey"), "PCR public key")
    )
    installed = serialization.load_pem_public_key(public_key)
    encoding = serialization.Encoding.DER
    fmt = serialization.PublicFormat.SubjectPublicKeyInfo
    if embedded.public_bytes(encoding, fmt) != installed.public_bytes(encoding, fmt):
        raise ValueError("TPM token has the wrong PCR public key")
    blobs = token.get("tpm2-blob")
    hashes = token.get("tpm2-policy-hash")
    if not isinstance(blobs, list) or len(blobs) != 2:
        raise ValueError("Combined TPM policy must have two sealed blobs")
    if not isinstance(hashes, list) or len(hashes) != 2:
        raise ValueError("Combined TPM policy must have two policy hashes")
    for blob in blobs:
        decoded(blob, "sealed blob")
    for value in hashes:
        if not isinstance(value, str) or len(bytes.fromhex(value)) != 32:
            raise ValueError("Invalid TPM policy hash")
    return token_id, slot


def main() -> None:
    if len(sys.argv) > 2 or (len(sys.argv) == 2 and sys.argv[1] != "--trial"):
        raise ValueError("Usage: tpm_unlock.py [--trial]")
    if os.geteuid() != 0 or Path("/etc/hostname").read_text().strip() != "halley2":
        raise ValueError("Run as root on Halley2")
    header = json.loads(
        subprocess.check_output(
            ["cryptsetup", "luksDump", "--dump-json-metadata", DEVICE], text=True
        )
    )
    token_id, slot = check_header(
        header, PUBLIC_KEY.read_bytes(), trial="--trial" in sys.argv
    )
    print(
        f"verified: token {token_id}, keyslot {slot}, pcrlock and signed PCR 11 metadata"
    )


if __name__ == "__main__":
    try:
        main()
    except (OSError, TypeError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"TPM unlock check failed: {exc}", file=sys.stderr)
        sys.exit(1)
