import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MASKS = [
    *(
        f"etc/nvpcr/{name}.nvpcr"
        for name in ("cryptsetup", "hardware", "login", "verity")
    ),
    "etc/systemd/system/systemd-pcrlogin@.service",
    "etc/systemd/system/systemd-pcrproduct.service",
]


class NvPCRTests(unittest.TestCase):
    def test_masks_are_empty_regular_files(self):
        for name in MASKS:
            path = ROOT / name
            self.assertFalse(path.is_symlink())
            self.assertEqual(path.read_bytes(), b"")

    def test_initramfs_keeps_existing_files_and_includes_masks(self):
        config = ROOT / "etc/mkinitcpio.conf.d/60-no-nvpcr.conf"
        output = subprocess.check_output(
            [
                "bash",
                "-c",
                'FILES=(existing); source "$1"; printf "%s\\n" "${FILES[@]}"',
                "bash",
                str(config),
            ],
            text=True,
        ).splitlines()
        self.assertEqual(output, ["existing", *(f"/{name}" for name in MASKS)])

    def test_srk_setup_and_pcr7_policy_remain_enabled(self):
        for name in ("systemd-tpm2-setup.service", "systemd-tpm2-setup-early.service"):
            self.assertFalse((ROOT / "etc/systemd/system" / name).exists())
        policy = (
            ROOT / "etc/systemd/system/systemd-pcrlock-make-policy.service.d/pcr7.conf"
        )
        self.assertIn("--pcr=7 --location=770", policy.read_text())
