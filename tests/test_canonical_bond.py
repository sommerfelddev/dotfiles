import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts import canonical_bond as bond


class BondTests(unittest.TestCase):
    def test_profile_source_uses_reported_filename_without_embedded_uuid(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "netplan wired:profile.nmconnection"
            source = "[connection]\nid=netplan-ethernet\ntype=ethernet\n"
            path.write_text(source)
            with (
                patch.object(
                    bond, "nmcli", return_value=f"other:/missing\nidentity:{path}"
                ) as command,
                patch.object(Path, "glob", return_value=[]),
            ):
                self.assertEqual(bond.profile_source("identity"), source)
            command.assert_called_once_with(
                "--escape", "no", "-g", "UUID,FILENAME", "connection", "show"
            )

    def test_profile_source_rejects_missing_filename(self):
        with (
            patch.object(bond, "nmcli", return_value="identity:"),
            self.assertRaisesRegex(ValueError, "No saved"),
        ):
            bond.profile_source("identity")

    @unittest.skipUnless(shutil.which("nmcli"), "nmcli is in the Nix development shell")
    def test_networkmanager_accepts_offline_profiles(self):
        config = bond.keyfile(bond.bond_profile())
        self.assertEqual(config["bond"]["fail_over_mac"], "active")
        for kind in ("ethernet", "wifi"):
            args = ["--offline", "con", "add", "type", kind, "ifname", "test0"]
            if kind == "wifi":
                args.extend(["ssid", "test"])
            profile = bond.port_profile(
                bond.nmcli(*args),
                kind,
                "74019c2b-26bb-42d9-a775-b715c70bbb58",
                100 if kind == "ethernet" else 0,
            )
            config = bond.keyfile(profile)
            self.assertNotIn("ipv4", config)
            self.assertNotIn("ipv6", config)
            self.assertEqual(config["connection"]["autoconnect"], "false")

    def test_activation_schedules_recovery_before_network_changes(self):
        script = bond.activation_commands(
            [{"original": "old", "uuid": "new"}], active={"old"}
        )
        self.assertLess(script.index("systemd-run"), script.index("install -m"))
        self.assertIn("--on-active=5m", script)
        self.assertIn("connection.autoconnect no", script)
        self.assertIn("con down uuid old", script)
        self.assertLess(script.index("con down uuid old"), script.index("con up uuid"))

    def test_recovery_restores_original_autoconnect_and_active_profiles(self):
        with patch.object(bond, "nmcli", return_value="old"):
            script = bond.recovery_commands(
                [{"original": "old", "uuid": "new", "autoconnect": "no"}]
            )
        self.assertIn("con mod uuid old connection.autoconnect no", script)
        self.assertIn("con up uuid old", script)
        self.assertNotIn("con delete uuid old", script)

    def test_bond_policy_and_identity(self):
        with patch.object(bond, "nmcli", return_value="profile") as command:
            self.assertEqual(bond.bond_profile(), "profile")
        args = command.call_args.args
        self.assertIn(
            "mode=active-backup,miimon=1000,fail_over_mac=active,primary_reselect=always",
            args,
        )
        self.assertEqual(args[args.index("ipv4.dhcp-client-id") + 1], "duid")
        self.assertEqual(args[args.index("ipv4.dhcp-iaid") + 1], "1")
        self.assertEqual(args[args.index("connection.autoconnect") + 1], "no")

    def test_ports_keep_authentication_but_remove_ip_settings(self):
        source = "[connection]\nid=wifi\nuuid=original\ntype=wifi\n[ipv4]\nmethod=auto\n[ipv6]\nmethod=auto\n[wifi-security]\nkey-mgmt=wpa-psk\npsk=example\n"
        with patch.object(bond, "nmcli", return_value="converted") as command:
            bond.port_profile(source, "wifi", "new", 0)
        args = command.call_args.args
        data = command.call_args.kwargs["input"]
        self.assertIn("psk=example", data)
        self.assertNotIn("[ipv4]", data)
        self.assertNotIn("[ipv6]", data)
        self.assertEqual(args[args.index("connection.controller") + 1], bond.BOND_UUID)
        self.assertEqual(
            args[args.index("802-11-wireless.cloned-mac-address") + 1], "permanent"
        )

    def test_ethernet_has_priority_over_wifi(self):
        with patch.object(bond, "nmcli", return_value="converted") as command:
            bond.port_profile("[connection]\ntype=ethernet\n", "ethernet", "new", 100)
        args = command.call_args.args
        self.assertEqual(args[args.index("bond-port.prio") + 1], "100")

    def test_rejects_other_profile_types(self):
        with self.assertRaises(ValueError):
            bond.port_profile("[connection]\ntype=bridge\n", "bridge", "new", 0)

    def test_does_not_drop_automatic_vpn_connections(self):
        with self.assertRaises(ValueError):
            bond.port_profile(
                "[connection]\ntype=ethernet\nsecondaries=vpn;\n",
                "ethernet",
                "new",
                100,
            )

    def test_generated_shell_scripts_parse(self):
        ports = [{"original": "old", "uuid": "new", "autoconnect": "yes"}]
        with patch.object(bond, "nmcli", return_value="old"):
            scripts = [bond.activation_commands(ports), bond.recovery_commands(ports)]
        for script in scripts:
            subprocess.run(["sh", "-n"], input=script, text=True, check=True)
            if shutil.which("shellcheck"):
                subprocess.run(
                    ["shellcheck", "-s", "sh", "-"], input=script, text=True, check=True
                )
