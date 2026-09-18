import importlib.util
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "canonical", ROOT / "scripts/canonical.py"
)
assert SPEC and SPEC.loader
canonical = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(canonical)


class PackageTests(unittest.TestCase):
    def test_subid_failure_remains_fatal_with_setup_guidance(self):
        def result(command, **kwargs):
            return subprocess.CompletedProcess(
                command, int(command[0] == "/usr/bin/getsubids")
            )

        with (
            patch.object(canonical.subprocess, "run", side_effect=result),
            patch("builtins.print") as printed,
            self.assertRaises(SystemExit) as failure,
        ):
            canonical.check()
        self.assertEqual(failure.exception.code, 1)
        self.assertTrue(
            any("just canonical-system" in str(call) for call in printed.call_args_list)
        )

    def test_install_does_not_enable_experimental_snap_features(self):
        with patch.object(canonical.subprocess, "run") as command:
            canonical.install()
        self.assertFalse(any("set" in call.args[0] for call in command.call_args_list))

    def test_keybase_is_not_installed_or_autostarted(self):
        self.assertNotIn("keybase", canonical.packages("snap"))
        self.assertFalse(
            (ROOT / "dot_config/autostart/dotfiles-keybase.desktop").exists()
        )

    def test_extensions_install_without_shell_confirmation(self):
        with (
            patch("sys.argv", ["canonical.py", "extensions"]),
            patch.object(canonical, "require_canonical"),
            patch.object(canonical.subprocess, "run") as command,
        ):
            canonical.main()
        self.assertEqual(
            command.call_args.args[0][:3], ["gext", "--filesystem", "install"]
        )

    def test_lab_check_rejects_missing_marker(self):
        with (
            patch.object(canonical.Path, "is_file", return_value=False),
            self.assertRaises(SystemExit),
        ):
            canonical.require_lab()

    def test_normal_check_keeps_company_registration(self):
        with patch.object(canonical.subprocess, "run") as command:
            command.return_value.returncode = 0
            canonical.check()
        self.assertTrue(
            any(
                call.args[0] == ["landscape-config", "--actively-registered"]
                for call in command.call_args_list
            )
        )
        self.assertTrue(
            any(
                call.args[0] == ["nix", "store", "ping", "--store", "daemon"]
                for call in command.call_args_list
            )
        )

    def test_non_corporate_role_is_rejected_before_system_access(self):
        with (
            patch.object(
                canonical.subprocess,
                "check_output",
                return_value='{"machineRole":"host"}',
            ),
            self.assertRaises(SystemExit),
        ):
            canonical.require_canonical()

    def test_classic_permission_is_explicit(self):
        commands = canonical.snap_install_commands()
        self.assertIn(
            ["sudo", "snap", "install", "ghostty", "--channel=stable", "--classic"],
            commands,
        )
        self.assertEqual(sum("--classic" in command for command in commands), 1)

    def test_flatpaks_are_user_scoped(self):
        commands = canonical.flatpak_install_commands()
        self.assertTrue(all("--user" in command for command in commands))
        self.assertIn("im.nheko.Nheko", commands[-1])

    def test_no_destructive_package_updates(self):
        commands = canonical.update_commands()
        self.assertIn(["sudo", "apt-get", "upgrade"], commands)
        self.assertFalse(
            any(
                "autoremove" in command or "dist-upgrade" in command
                for command in commands
            )
        )
        self.assertFalse(any("--ignore-running" in command for command in commands))


class RoleTests(unittest.TestCase):
    def command(self, role: str, *args: str) -> list[str]:
        return [
            "chezmoi",
            "--config",
            "/dev/null",
            "--config-format",
            "toml",
            "--override-data",
            json.dumps(
                {
                    "machineRole": role,
                    "workName": "Work User",
                    "workEmail": "work@canonical.com",
                    "workSigningKey": "A" * 40,
                }
            ),
            "-S",
            str(ROOT),
            *args,
        ]

    def test_podman_units_are_managed_for_all_roles(self):
        for role in ["host", "vm", "canonical"]:
            with self.subTest(role=role):
                files = subprocess.check_output(
                    self.command(role, "managed", "--include=files"), text=True
                ).splitlines()
                for unit in ["podman.socket", "podman.service"]:
                    self.assertIn(f".config/systemd/user/{unit}", files)

    def test_canonical_file_boundary(self):
        files = subprocess.check_output(
            self.command("canonical", "managed", "--include=files,scripts,symlinks"),
            text=True,
        ).splitlines()
        for required in [
            ".ssh/config",
            ".gnupg/gpg.conf",
            ".config/git/config",
            ".config/ghostty/config",
            ".local/bin/rqr",
            ".local/share/gnome-shell/extensions/corporate-panel@dotfiles/extension.js",
        ]:
            self.assertIn(required, files)
        for path in files:
            self.assertFalse(
                any(
                    part in path
                    for part in [
                        "sway",
                        "waybar",
                        "nym.pub",
                        "sshcontrol",
                        "pass-secret-service",
                        ".config/git/hooks",
                        "deploy-etc",
                    ]
                )
            )
            self.assertNotIn("__pycache__", path)
            self.assertNotEqual(path, ".config/nvim/nvim-pack-lock.json")
            if path.endswith(".sh") and not path.startswith("."):
                self.assertIn(path, ["canonical-desktop.sh", "canonical-nvim-lock.sh"])

    def test_canonical_lockfile_is_seeded_without_overwriting(self):
        rendered = subprocess.check_output(
            self.command(
                "canonical",
                "execute-template",
                "--file",
                str(ROOT / "run_before_canonical-nvim-lock.sh.tmpl"),
            ),
            text=True,
        )
        with tempfile.TemporaryDirectory() as directory:
            env = {
                **os.environ,
                "HOME": directory,
                "XDG_CONFIG_HOME": directory + "/config",
            }
            target = Path(directory) / "config/nvim/nvim-pack-lock.json"
            subprocess.run(["sh", "-c", rendered], env=env, check=True)
            self.assertEqual(
                target.read_bytes(),
                (ROOT / "dot_config/nvim/nvim-pack-lock.json").read_bytes(),
            )
            target.write_text('{"local": true}\n')
            subprocess.run(["sh", "-c", rendered], env=env, check=True)
            self.assertEqual(target.read_text(), '{"local": true}\n')

    def test_work_identity_is_rendered_without_personal_identity(self):
        for source in [
            "dot_config/git/config.tmpl",
            "private_dot_ssh/config.tmpl",
            "private_dot_gnupg/gpg.conf.tmpl",
        ]:
            rendered = subprocess.check_output(
                self.command(
                    "canonical", "execute-template", "--file", str(ROOT / source)
                ),
                text=True,
            )
            self.assertNotIn("sommerfeld", rendered)
            self.assertNotIn("nym.pub", rendered)
            self.assertNotIn("proton/", rendered)

    def test_host_and_vm_do_not_receive_corporate_autostart(self):
        for role in ["host", "vm"]:
            files = subprocess.check_output(
                self.command(role, "managed", "--include=files,symlinks"), text=True
            )
            self.assertNotIn(".config/autostart/dotfiles-", files)
            self.assertNotIn("gpg-agent.service.d/canonical.conf", files)
            self.assertNotIn("corporate-panel@dotfiles", files)


if __name__ == "__main__":
    unittest.main()
