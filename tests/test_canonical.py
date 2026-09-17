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


if __name__ == "__main__":
    unittest.main()
