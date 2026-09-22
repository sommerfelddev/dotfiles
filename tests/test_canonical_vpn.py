import tempfile
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

from scripts import canonical_vpn as vpn


class VpnTests(unittest.TestCase):
    def archive(self, root, key="person@2.key"):
        archive = root / "credentials.zip"
        with zipfile.ZipFile(archive, "w") as output:
            output.writestr(
                "uk-person@2.conf",
                f"client\nremote uk.sesame.canonical.com 673\nca ca.crt\ncert person@2.crt\nkey {key}\ntls-auth ta.key 1\nverify-x509-name 'access.is' name\n",
            )
            for name in ("ca.crt", "ta.key", "person@2.crt", key, "primary.key"):
                output.writestr(name, f"test data for {name}")
        return archive

    def test_extracts_only_secondary_dependencies_and_rewrites_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            destination = root / "private credentials"
            files = vpn.secondary_files(self.archive(root), "uk", destination)
        self.assertEqual(
            set(files),
            {
                "canonical-secondary.conf",
                "ca.crt",
                "ta.key",
                "person@2.crt",
                "person@2.key",
            },
        )
        config = files["canonical-secondary.conf"].decode()
        self.assertIn(str(destination / "person@2.key"), config)
        self.assertIn("tls-auth", config)
        self.assertIn(" 1\n", config)
        self.assertIn("verify-x509-name 'access.is' name", config)

    def test_rejects_primary_identity_reference(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(ValueError, "secondary"):
                vpn.secondary_files(self.archive(root, "person.key"), "uk", root)

    def test_rejects_path_traversal(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaises(ValueError):
                vpn.secondary_files(self.archive(root, "../person@2.key"), "uk", root)

    def test_private_files_are_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "secondary"
            vpn.write_credentials(target, {"file": b"first"})
            self.assertEqual(target.stat().st_mode & 0o777, 0o700)
            self.assertEqual((target / "file").stat().st_mode & 0o777, 0o600)
            vpn.write_credentials(target, {"file": b"first"})
            with self.assertRaises(ValueError):
                vpn.write_credentials(target, {"file": b"changed"})
            self.assertEqual((target / "file").read_bytes(), b"first")

    def test_modes_control_both_ip_families_and_dns(self):
        full = vpn.routing("full")
        split = vpn.routing("split")
        for family in ("ipv4", "ipv6"):
            self.assertEqual(full[full.index(f"{family}.never-default") + 1], "no")
            self.assertEqual(split[split.index(f"{family}.never-default") + 1], "yes")
            self.assertEqual(full[full.index(f"{family}.dns-search") + 1], "~.")
        with self.assertRaises(ValueError):
            vpn.routing("invalid")

    def test_up_refuses_to_change_an_active_profile(self):
        with (
            patch.object(vpn, "output", return_value=vpn.NAME),
            patch.object(vpn, "run") as run,
            self.assertRaisesRegex(ValueError, "Disconnect"),
        ):
            vpn.up("split")
        run.assert_not_called()

    def test_up_applies_mode_before_connection(self):
        with (
            patch.object(vpn, "output", return_value=""),
            patch.object(vpn, "run") as run,
        ):
            vpn.up("full")
        self.assertEqual(run.call_args_list[0].args[0][-12:], vpn.routing("full"))
        self.assertEqual(
            run.call_args_list[1].args[0],
            ["nmcli", "--ask", "connection", "up", "id", vpn.NAME],
        )

    def test_existing_profile_is_not_replaced(self):
        with (
            patch.object(vpn, "output", return_value=vpn.NAME),
            patch.object(vpn, "write_credentials") as write,
            self.assertRaisesRegex(ValueError, "already exists"),
        ):
            vpn.install(Path("archive.zip"), "uk")
        write.assert_not_called()

    def test_symlink_directory_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            target = root / "secondary"
            target.symlink_to(root, target_is_directory=True)
            with self.assertRaisesRegex(ValueError, "symlinks"):
                vpn.write_credentials(target, {"key": b"secret"})
            self.assertFalse((root / "key").exists())

    def test_install_does_not_connect_or_attach_to_bond(self):
        with (
            patch.object(vpn, "output", return_value=""),
            patch.object(vpn, "secondary_files", return_value={}),
            patch.object(vpn, "write_credentials"),
            patch.object(vpn, "run") as run,
        ):
            vpn.install(Path("archive.zip"), "uk")
        commands = [call.args[0] for call in run.call_args_list]
        self.assertTrue(any("import" in command for command in commands))
        self.assertFalse(
            any(
                "up" in command or "connection.secondaries" in command
                for command in commands
            )
        )
        modified = commands[-1]
        self.assertEqual(modified[modified.index("connection.autoconnect") + 1], "no")
        for family in ("ipv4", "ipv6"):
            self.assertEqual(
                modified[modified.index(f"{family}.never-default") + 1], "yes"
            )
