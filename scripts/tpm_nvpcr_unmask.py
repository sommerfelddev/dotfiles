"""Remove only the old NvPCR masks owned by this repository."""

import hashlib
import os
from pathlib import Path

MASKS = [
    *(
        Path(f"/etc/nvpcr/{name}.nvpcr")
        for name in ("cryptsetup", "hardware", "login", "verity")
    ),
    Path("/etc/systemd/system/systemd-pcrlogin@.service"),
    Path("/etc/systemd/system/systemd-pcrproduct.service"),
]
DROPIN = Path("/etc/mkinitcpio.conf.d/60-no-nvpcr.conf")
DROPIN_SHA256 = "69a242f865bbd1adee85f168f19e0f4e5b94a78b3d65e5dfa976c5e0f76deea4"
RECOVERY = Path("/boot/EFI/Linux/arch-linux-hardened-nvpcr-recovery.efi")
BACKUP = Path("/var/lib/dotfiles/tpm-nvpcr/backup")


def validate(paths: list[Path]) -> list[Path]:
    removable = []
    for path in paths:
        if not path.exists() and not path.is_symlink():
            continue
        if not path.is_file() or path.is_symlink():
            raise ValueError(f"Expected a regular file: {path}")
        data = path.read_bytes()
        if path == DROPIN:
            if hashlib.sha256(data).hexdigest() != DROPIN_SHA256:
                raise ValueError(f"Old mkinitcpio drop-in was changed: {path}")
        elif data:
            raise ValueError(f"NvPCR mask is not empty: {path}")
        removable.append(path)
    return removable


def main() -> None:
    if os.geteuid() != 0 or Path("/etc/hostname").read_text().strip() != "halley2":
        raise ValueError("Run as root on Halley2")
    if not RECOVERY.is_file() or not BACKUP.is_dir():
        raise ValueError("Recovery image and backup must exist before removing masks")
    removable = validate([*MASKS, DROPIN])
    for path in removable:
        path.unlink()
        print(f"removed: {path}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as exc:
        raise SystemExit(f"NvPCR unmask failed: {exc}") from exc
