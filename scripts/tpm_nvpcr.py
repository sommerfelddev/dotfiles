"""Read-only checks for Halley2's signed NvPCR UKIs."""

import base64
import hashlib
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pefile
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa

BOOT = Path("/boot/EFI/Linux")
PCRLOCK_POLICY = Path("/var/lib/systemd/pcrlock.json")
GPT_COMPONENT = Path("/var/lib/pcrlock.d/600-gpt.pcrlock.d/generated.pcrlock")
PUBLIC_KEY = Path("/etc/systemd/tpm2-pcr-public-key.pem")
SB_CERT = Path("/var/lib/sbctl/keys/db/db.pem")
ROOT_UUID = "81520bbc-1e7a-45e6-9465-cfc2e8b18945"
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
POLICY_REFS = ("initrd", "luks-root")
MEASURED_SECTIONS = frozenset(
    (
        ".linux",
        ".osrel",
        ".cmdline",
        ".initrd",
        ".ucode",
        ".splash",
        ".dtb",
        ".uname",
        ".sbat",
        ".pcrpkey",
        ".profile",
        ".hwids",
    )
)


def run(*command: str) -> str:
    try:
        result = subprocess.run(command, capture_output=True, text=True, check=True)
    except subprocess.CalledProcessError as exc:
        detail = (exc.stderr or exc.stdout or "no error output").strip()
        raise RuntimeError(f"{command[0]} exited {exc.returncode}: {detail}") from exc
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
    for ref in POLICY_REFS:
        if not isinstance(policies, dict) or not any(
            isinstance(item, dict)
            and item.get("pcrs") == [11]
            and item.get("ref") == ref
            and isinstance(item.get("sig"), str)
            and bool(item["sig"])
            for item in policies.get("sha256", [])
        ):
            raise ValueError(f"UKI has no signed {ref} PCR 11 policy")

    cmdline = sections.get(".cmdline")
    if not isinstance(cmdline, dict) or not isinstance(cmdline.get("text"), str):
        raise TypeError("UKI has no kernel command line")
    args = cmdline["text"].split()
    roots = [arg.split("=", 2)[1] for arg in args if arg.startswith("rd.luks.name=")]
    if roots != [ROOT_UUID]:
        raise ValueError("UKI has the wrong LUKS root UUID")
    options = [
        arg.removeprefix("rd.luks.options=")
        for arg in args
        if arg.startswith("rd.luks.options=")
    ]
    if len(options) != 1 or not options[0].startswith(roots[0] + "="):
        raise ValueError("Root measurement options have the wrong LUKS UUID")
    if "root=/dev/mapper/root" not in args:
        raise ValueError("UKI does not boot the expected root mapping")
    selected = options[0].split("=", 1)[1].split(",")
    if not all(option in selected for option in MEASUREMENT_OPTIONS):
        raise ValueError("Root measurement or TPM unlock option is missing")


def check_initrd_listing(listing: str) -> None:
    members = {line.strip().lstrip("./") for line in listing.splitlines()}
    for unit in INITRD_UNITS:
        if f"usr/lib/systemd/system/{unit}" not in members:
            raise ValueError(f"UKI initrd lacks {unit}")


def read_pe_sections(path: Path) -> dict[str, bytes]:
    pe = pefile.PE(str(path), fast_load=True)
    sections = {}
    for section in pe.sections:
        name = section.Name.rstrip(b"\0").decode("ascii")
        if name in sections:
            raise ValueError(f"Duplicate UKI section: {name}")
        size = min(section.Misc_VirtualSize, section.SizeOfRawData)
        sections[name] = section.get_data(length=size)
    if ".dtbauto" in sections:
        raise ValueError(
            "Automatic device tree selection is not supported by this checker"
        )
    return sections


def verify_pcr_signatures(
    sections: dict[str, bytes], public_key: bytes, refs: tuple[str, ...] = POLICY_REFS
) -> None:
    if sections.get(".pcrpkey") != public_key:
        raise ValueError("UKI PCR public key does not match the installed key")
    try:
        signed = json.loads(sections[".pcrsig"].decode().rstrip("\0"))
        key = serialization.load_pem_public_key(public_key)
    except (KeyError, ValueError, TypeError) as exc:
        raise ValueError("Invalid UKI PCR signature or public key") from exc
    if not isinstance(key, rsa.RSAPublicKey):
        raise TypeError("PCR public key must be RSA")

    measured = {
        name: data for name, data in sections.items() if name in MEASURED_SECTIONS
    }
    if ".linux" not in measured or ".initrd" not in measured:
        raise ValueError("UKI lacks a kernel or initrd")

    with tempfile.TemporaryDirectory() as directory:
        options = []
        for name, data in measured.items():
            section_path = Path(directory) / name.removeprefix(".")
            section_path.write_bytes(data)
            options.append(f"--{name.removeprefix('.')}={section_path}")
        for ref in refs:
            expected = json.loads(
                run(
                    "/usr/lib/systemd/systemd-measure",
                    "policy-digest",
                    "--json=short",
                    "--bank=sha256",
                    "--phase=enter-initrd",
                    f"--policyref={ref}",
                    f"--public-key={PUBLIC_KEY}",
                    *options,
                )
            )["sha256"]
            if len(expected) != 1:
                raise ValueError(f"Unexpected PCR policy count for {ref}")
            matching = [
                item
                for item in signed.get("sha256", [])
                if item.get("pcrs") == [11] and item.get("ref") == ref
            ]
            if len(matching) != 1:
                raise ValueError(f"Expected one {ref} PCR 11 signature")
            actual = matching[0]
            policy = expected[0]
            if any(
                actual.get(field) != policy.get(field)
                for field in ("pcrs", "pkfp", "ref", "pol")
            ):
                raise ValueError(f"{ref} PCR 11 signature does not match UKI contents")
            try:
                signature = base64.b64decode(actual["sig"], validate=True)
                key.verify(
                    signature,
                    bytes.fromhex(policy["tbs"]),
                    padding.PKCS1v15(),
                    hashes.SHA256(),
                )
            except (KeyError, ValueError, InvalidSignature) as exc:
                raise ValueError(f"Invalid {ref} PCR 11 signature") from exc


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
    verify_pcr_signatures(read_pe_sections(path), public_key)
    check_initrd_listing(run("lsinitcpio", "--list", str(path)))
    run("sbverify", "--cert", str(SB_CERT), str(path))
    print(f"verified: {path}")


def check_pcrlock_policy(policy: dict, boot_policy: dict) -> None:
    values = policy.get("pcrValues")
    if (
        policy.get("pcrBank") != "sha256"
        or not isinstance(values, list)
        or len(values) != 2
        or any(
            not isinstance(entry, dict)
            or entry.get("pcr") not in (5, 7)
            or not isinstance(entry.get("values"), list)
            or not entry["values"]
            for entry in values
        )
        or {entry["pcr"] for entry in values} != {5, 7}
    ):
        raise ValueError("Stored pcrlock policy does not require PCR 5 and PCR 7")
    if policy != boot_policy:
        raise ValueError("EFI pcrlock credential differs from the stored policy")


def check_boot_policy() -> None:
    if not GPT_COMPONENT.is_file():
        raise ValueError("Approved GPT component is missing")
    policy = json.loads(PCRLOCK_POLICY.read_text())
    credential_dir = Path(run("bootctl", "-x").strip()) / "loader/credentials"
    credentials = list(credential_dir.glob("pcrlock.*.cred"))
    if len(credentials) != 1:
        raise ValueError("Expected one EFI pcrlock credential")
    credential = credentials[0]
    name = credential.name.removesuffix(".cred").lower()
    boot_policy = json.loads(
        run(
            "systemd-creds",
            "--allow-null",
            f"--name={name}",
            "decrypt",
            str(credential),
            "-",
        )
    )
    check_pcrlock_policy(policy, boot_policy)


def check_boot() -> None:
    active = Path("/proc/cmdline").read_text()
    if not all(option in active for option in MEASUREMENT_OPTIONS):
        raise ValueError("Current boot did not use the NvPCR root options")
    nvpcrs = run("systemd-analyze", "nvpcrs", "--no-pager")
    for name in ("cryptsetup", "hardware", "login", "verity"):
        if name not in nvpcrs:
            raise ValueError(f"NvPCR {name} is not available")
    check_boot_policy()
    run(
        "/usr/lib/systemd/systemd-pcrlock",
        "--strict=yes",
        "--pcr=5",
        "--pcr=7",
        "--location=770",
        "predict",
    )
    failed = run("systemctl", "--failed", "--no-legend", "--no-pager")
    if failed.strip():
        raise ValueError("Systemd has failed units; inspect systemctl --failed")
    print(
        "verified: current boot options, NvPCR availability, and strict PCR 5+7 policy"
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
    except (OSError, TypeError, ValueError, RuntimeError) as exc:
        print(f"NvPCR check failed: {exc}", file=sys.stderr)
        sys.exit(1)
