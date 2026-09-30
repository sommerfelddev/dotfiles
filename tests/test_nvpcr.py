import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from scripts import tpm_nvpcr, tpm_nvpcr_unmask

ROOT = Path(__file__).resolve().parents[1]


class NvPCRConfigTests(unittest.TestCase):
    def test_hook_adds_required_initrd_services(self):
        hook = ROOT / "etc/initcpio/install/nvpcr"
        output = subprocess.check_output(
            [
                "bash",
                "-c",
                'map() { "$@"; }; add_systemd_unit() { printf "%s\\n" "$@"; }; source "$1"; build',
                "bash",
                str(hook),
            ],
            text=True,
        ).splitlines()
        self.assertEqual(
            set(output),
            {
                "systemd-tpm2-setup-early.service",
                "systemd-pcrnvdone.service",
                "systemd-pcrextend.socket",
                "systemd-pcrextend@.service",
            },
        )
        self.assertIn(
            "etc/initcpio/install/*)",
            (ROOT / "run_onchange_after_deploy-etc.sh.tmpl").read_text(),
        )

    def test_deploy_requires_a_signed_recovery_image_and_backup(self):
        script = (ROOT / "run_onchange_after_deploy-etc.sh.tmpl").read_text()
        self.assertIn("backup/etc.tar", script)
        self.assertIn("backup/arch-linux-lts-fallback.efi", script)
        self.assertIn("sudo sbverify --cert", script)

    def test_pcr7_policy_is_unchanged(self):
        policy = (
            ROOT / "etc/systemd/system/systemd-pcrlock-make-policy.service.d/pcr7.conf"
        )
        self.assertIn("--pcr=7 --location=770", policy.read_text())
        for name in ("systemd-tpm2-setup.service", "systemd-tpm2-setup-early.service"):
            self.assertFalse((ROOT / "etc/systemd/system" / name).exists())

    def test_uki_signs_only_the_initrd_referenced_policy(self):
        config = (ROOT / "etc/kernel/uki.conf").read_text()
        self.assertIn("PolicyRef=initrd", config)
        self.assertIn("Phases=enter-initrd", config)
        self.assertNotIn("SignInitrdPCRs=", config)

    def test_old_masks_are_not_in_source(self):
        for name in ("cryptsetup", "hardware", "login", "verity"):
            self.assertFalse((ROOT / f"etc/nvpcr/{name}.nvpcr").exists())
        self.assertFalse((ROOT / "etc/mkinitcpio.conf.d/60-no-nvpcr.conf").exists())
        for name in ("systemd-pcrlogin@.service", "systemd-pcrproduct.service"):
            self.assertFalse((ROOT / "etc/systemd/system" / name).exists())


def sections(public_key, *, policies=None, options=None):
    if policies is None:
        policies = {"sha256": [{"pcrs": [11], "ref": "initrd", "sig": "signature"}]}
    if options is None:
        options = (
            "tpm2-device=auto,tpm2-measure-pcr=15,tpm2-measure-keyslot-nvpcr=cryptsetup"
        )
    return {
        ".pcrpkey": {"sha256": hashlib.sha256(public_key).hexdigest()},
        ".pcrsig": {"text": json.dumps(policies)},
        ".cmdline": {
            "text": f"rd.luks.name=uuid=root rd.luks.options=uuid={options} root=/dev/mapper/root"
        },
    }


class NvPCRImageTests(unittest.TestCase):
    def test_valid_initrd_signature_and_root_options(self):
        tpm_nvpcr.check_sections(sections(b"public key"), b"public key")

    def test_rejects_wrong_public_key(self):
        with self.assertRaisesRegex(ValueError, "public key"):
            tpm_nvpcr.check_sections(sections(b"one"), b"two")

    def test_rejects_policy_without_initrd_reference(self):
        bad = {"sha256": [{"pcrs": [11], "ref": "system", "sig": "signature"}]}
        with self.assertRaisesRegex(ValueError, "initrd PCR 11"):
            tpm_nvpcr.check_sections(sections(b"key", policies=bad), b"key")

    def test_rejects_unsigned_initrd_policy(self):
        bad = {"sha256": [{"pcrs": [11], "ref": "initrd"}]}
        with self.assertRaisesRegex(ValueError, "initrd PCR 11"):
            tpm_nvpcr.check_sections(sections(b"key", policies=bad), b"key")

    def test_rejects_missing_tpm_selection(self):
        with self.assertRaisesRegex(ValueError, "option is missing"):
            tpm_nvpcr.check_sections(
                sections(
                    b"key",
                    options="tpm2-measure-pcr=15,tpm2-measure-keyslot-nvpcr=cryptsetup",
                ),
                b"key",
            )

    def test_rejects_wrong_root_uuid(self):
        image = sections(b"key")
        image[".cmdline"]["text"] = image[".cmdline"]["text"].replace(
            "rd.luks.options=uuid=", "rd.luks.options=other="
        )
        with self.assertRaisesRegex(ValueError, "wrong LUKS UUID"):
            tpm_nvpcr.check_sections(image, b"key")


class NvPCRUnmaskTests(unittest.TestCase):
    def test_refuses_any_modified_file_before_deleting_masks(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first = root / "first.nvpcr"
            changed = root / "second.nvpcr"
            first.touch()
            changed.write_text("owned by user")
            with self.assertRaisesRegex(ValueError, "not empty"):
                tpm_nvpcr_unmask.validate([first, changed])
            self.assertTrue(first.exists())

    def test_accepts_only_expected_dropin_contents(self):
        with tempfile.TemporaryDirectory() as directory:
            dropin = Path(directory) / "dropin.conf"
            dropin.write_text("changed")
            with (
                mock.patch.object(tpm_nvpcr_unmask, "DROPIN", dropin),
                self.assertRaisesRegex(ValueError, "was changed"),
            ):
                tpm_nvpcr_unmask.validate([dropin])


if __name__ == "__main__":
    unittest.main()
