import base64
import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

from scripts import tpm_negative_uki, tpm_nvpcr, tpm_nvpcr_unmask, tpm_unlock

ROOT = Path(__file__).resolve().parents[1]


class NvPCRConfigTests(unittest.TestCase):
    def test_check_recipe_accepts_no_images_or_one_image(self):
        for images in ((), ("candidate.efi",)):
            output = subprocess.check_output(
                ["just", "--dry-run", "tpm-nvpcr-check", *images],
                cwd=ROOT,
                stderr=subprocess.STDOUT,
                text=True,
            )
            self.assertIn("scripts/tpm_nvpcr.py", output)

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

    def test_deploy_requires_a_signed_main_image_and_backup(self):
        script = (ROOT / "run_onchange_after_deploy-etc.sh.tmpl").read_text()
        self.assertIn("backup/etc.tar", script)
        self.assertIn("backup/arch-linux-lts-fallback.efi", script)
        self.assertIn("sudo sbverify --cert", script)
        self.assertNotIn("arch-linux-hardened-nvpcr-recovery.efi", script)

    def test_pcr7_policy_is_unchanged(self):
        policy = (
            ROOT / "etc/systemd/system/systemd-pcrlock-make-policy.service.d/pcr7.conf"
        )
        self.assertIn("--pcr=7 --location=770", policy.read_text())
        for name in ("systemd-tpm2-setup.service", "systemd-tpm2-setup-early.service"):
            self.assertFalse((ROOT / "etc/systemd/system" / name).exists())

    def test_uki_signs_initrd_and_root_policies(self):
        config = (ROOT / "etc/kernel/uki.conf").read_text()
        self.assertIn("PolicyRef=initrd", config)
        self.assertIn("PolicyRef=luks-root", config)
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
        policies = {
            "sha256": [
                {"pcrs": [11], "ref": ref, "sig": "signature"}
                for ref in tpm_nvpcr.POLICY_REFS
            ]
        }
    if options is None:
        options = (
            "tpm2-device=auto,tpm2-measure-pcr=15,tpm2-measure-keyslot-nvpcr=cryptsetup"
        )
    return {
        ".pcrpkey": {"sha256": hashlib.sha256(public_key).hexdigest()},
        ".pcrsig": {"text": json.dumps(policies)},
        ".cmdline": {
            "text": f"rd.luks.name={tpm_nvpcr.ROOT_UUID}=root rd.luks.options={tpm_nvpcr.ROOT_UUID}={options} root=/dev/mapper/root"
        },
    }


class NvPCRImageTests(unittest.TestCase):
    def test_command_failure_reports_stderr(self):
        error = subprocess.CalledProcessError(1, ["ukify"], stderr="file not found")
        with (
            mock.patch.object(tpm_nvpcr.subprocess, "run", side_effect=error),
            self.assertRaisesRegex(RuntimeError, "ukify exited 1: file not found"),
        ):
            tpm_nvpcr.run("ukify", "inspect", "missing.efi")

    def test_initrd_has_required_units(self):
        listing = "\n".join(
            f"usr/lib/systemd/system/{unit}" for unit in tpm_nvpcr.INITRD_UNITS
        )
        tpm_nvpcr.check_initrd_listing(listing)

    def test_rejects_missing_initrd_service(self):
        listing = "\n".join(
            f"usr/lib/systemd/system/{unit}"
            for unit in tpm_nvpcr.INITRD_UNITS
            if unit != "systemd-pcrnvdone.service"
        )
        with self.assertRaisesRegex(ValueError, "systemd-pcrnvdone.service"):
            tpm_nvpcr.check_initrd_listing(listing)

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

    def test_rejects_missing_root_policy(self):
        bad = {"sha256": [{"pcrs": [11], "ref": "initrd", "sig": "signature"}]}
        with self.assertRaisesRegex(ValueError, "luks-root PCR 11"):
            tpm_nvpcr.check_sections(sections(b"key", policies=bad), b"key")

    def test_pcr_signatures_match_measured_sections(self):
        key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        private = key.private_bytes(
            serialization.Encoding.PEM,
            serialization.PrivateFormat.PKCS8,
            serialization.NoEncryption(),
        )
        public = key.public_key().public_bytes(
            serialization.Encoding.PEM,
            serialization.PublicFormat.SubjectPublicKeyInfo,
        )
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            private_path = root / "private.pem"
            public_path = root / "public.pem"
            private_path.write_bytes(private)
            private_path.chmod(0o600)
            public_path.write_bytes(public)
            image = {
                ".linux": b"kernel",
                ".initrd": b"initrd",
                ".pcrpkey": public,
                ".cmdline": b"root=/dev/mapper/root",
            }
            args = []
            for name, content in image.items():
                path = root / name.removeprefix(".")
                path.write_bytes(content)
                args.append(f"--{name.removeprefix('.')}={path}")
            signatures = []
            for ref in tpm_nvpcr.POLICY_REFS:
                result = subprocess.check_output(
                    [
                        "/usr/lib/systemd/systemd-measure",
                        "sign",
                        "--bank=sha256",
                        "--phase=enter-initrd",
                        f"--policyref={ref}",
                        f"--private-key={private_path}",
                        f"--public-key={public_path}",
                        *args,
                    ],
                    text=True,
                )
                signatures.extend(json.loads(result)["sha256"])
            image[".pcrsig"] = json.dumps({"sha256": signatures}).encode()
            with mock.patch.object(tpm_nvpcr, "PUBLIC_KEY", public_path):
                tpm_nvpcr.verify_pcr_signatures(image, public)
                changed = dict(image, **{".initrd": b"changed"})
                with self.assertRaisesRegex(ValueError, "does not match UKI contents"):
                    tpm_nvpcr.verify_pcr_signatures(changed, public)
                changed = json.loads(image[".pcrsig"])
                changed["sha256"][1]["sig"] = base64.b64encode(b"wrong").decode()
                image[".pcrsig"] = json.dumps(changed).encode()
                with self.assertRaisesRegex(
                    ValueError, "Invalid luks-root PCR 11 signature"
                ):
                    tpm_nvpcr.verify_pcr_signatures(image, public)

    def test_ukify_image_signatures_match_its_sections(self):
        key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            private = root / "private.pem"
            public = root / "public.pem"
            private.write_bytes(
                key.private_bytes(
                    serialization.Encoding.PEM,
                    serialization.PrivateFormat.PKCS8,
                    serialization.NoEncryption(),
                )
            )
            private.chmod(0o600)
            public.write_bytes(
                key.public_key().public_bytes(
                    serialization.Encoding.PEM,
                    serialization.PublicFormat.SubjectPublicKeyInfo,
                )
            )
            initrd = root / "initrd"
            initrd.write_bytes(b"test initrd")
            config = root / "uki.conf"
            config.write_text(
                f"[UKI]\nPCRPKey={public}\nPCRBanks=sha256\n\n"
                + "".join(
                    f"[PCRSignature:{ref}]\nPCRPrivateKey={private}\n"
                    f"PCRPublicKey={public}\nPhases=enter-initrd\nPolicyRef={ref}\n\n"
                    for ref in tpm_nvpcr.POLICY_REFS
                )
            )
            output = root / "test.efi"
            subprocess.run(
                [
                    "ukify",
                    "build",
                    "--config",
                    str(config),
                    "--linux=/usr/bin/true",
                    f"--initrd={initrd}",
                    f"--output={output}",
                ],
                check=True,
                capture_output=True,
            )
            sb_key = root / "secureboot.key"
            sb_cert = root / "secureboot.pem"
            subprocess.run(
                [
                    "openssl",
                    "req",
                    "-x509",
                    "-newkey",
                    "rsa:2048",
                    "-nodes",
                    "-keyout",
                    str(sb_key),
                    "-out",
                    str(sb_cert),
                    "-days",
                    "1",
                    "-subj",
                    "/CN=UKI test",
                ],
                check=True,
                capture_output=True,
            )
            signed = root / "signed.efi"
            subprocess.run(
                [
                    "sbsign",
                    "--key",
                    str(sb_key),
                    "--cert",
                    str(sb_cert),
                    "--output",
                    str(signed),
                    str(output),
                ],
                check=True,
                capture_output=True,
            )
            with mock.patch.object(tpm_nvpcr, "PUBLIC_KEY", public):
                tpm_nvpcr.verify_pcr_signatures(
                    tpm_nvpcr.read_pe_sections(signed), public.read_bytes()
                )
                negative = root / "negative.efi"
                tpm_negative_uki.remove_root_approval(
                    signed, negative, public.read_bytes()
                )
                changed = tpm_nvpcr.read_pe_sections(negative)
                tpm_nvpcr.verify_pcr_signatures(
                    changed, public.read_bytes(), refs=("initrd",)
                )
                with self.assertRaisesRegex(ValueError, "luks-root"):
                    tpm_nvpcr.verify_pcr_signatures(changed, public.read_bytes())
                resigned = root / "resigned.efi"
                subprocess.run(
                    [
                        "sbsign",
                        "--key",
                        str(sb_key),
                        "--cert",
                        str(sb_cert),
                        "--output",
                        str(resigned),
                        str(negative),
                    ],
                    check=True,
                    capture_output=True,
                )
                subprocess.run(
                    ["sbverify", "--cert", str(sb_cert), str(resigned)],
                    check=True,
                )

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
            f"rd.luks.options={tpm_nvpcr.ROOT_UUID}=", "rd.luks.options=other="
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


class TPMUnlockTests(unittest.TestCase):
    def test_combined_token_and_trial_slot(self):
        key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        public = key.public_key().public_bytes(
            serialization.Encoding.PEM,
            serialization.PublicFormat.SubjectPublicKeyInfo,
        )
        token = {
            "type": "systemd-tpm2",
            "keyslots": ["2"],
            "tpm2-pcrs": [],
            "tpm2-pcr-bank": "sha256",
            "tpm2_pcrlock": True,
            "tpm2_pcrlock_nv": base64.b64encode(b"nv").decode(),
            "tpm2_pubkey_pcrs": [11],
            "tpm2_pubkey_ref": "luks-root",
            "tpm2_pubkey": base64.b64encode(public).decode(),
            "tpm2-blob": [base64.b64encode(b"blob").decode()] * 2,
            "tpm2-policy-hash": ["a0" * 32] * 2,
        }
        header = {"tokens": {"1": token}, "keyslots": {"0": {}, "1": {}, "2": {}}}
        self.assertEqual(
            tpm_unlock.check_header(header, public, trial=True), ("1", "2")
        )
        with self.assertRaisesRegex(ValueError, "extra keyslot"):
            tpm_unlock.check_header(header, public)
        del header["keyslots"]["1"]
        self.assertEqual(tpm_unlock.check_header(header, public), ("1", "2"))
        token["tpm2_pubkey_ref"] = "initrd"
        with self.assertRaisesRegex(ValueError, "luks-root"):
            tpm_unlock.check_header(header, public)
        token["tpm2_pubkey_ref"] = "luks-root"
        token["tpm2_pcrlock"] = False
        with self.assertRaisesRegex(ValueError, "pcrlock"):
            tpm_unlock.check_header(header, public)
        token["tpm2_pcrlock"] = True
        token["tpm2-blob"] = token["tpm2-blob"][:1]
        with self.assertRaisesRegex(ValueError, "two sealed blobs"):
            tpm_unlock.check_header(header, public)


if __name__ == "__main__":
    unittest.main()
