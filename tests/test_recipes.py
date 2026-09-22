import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RecipeTests(unittest.TestCase):
    def invoke(self, role, *recipes):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            commands = {
                "chezmoi": 'if [ "$1" = data ]; then printf \'%s\\n\' "$ROLE_DATA"; else echo "chezmoi $*"; fi',
                "sudo": 'echo "UNEXPECTED sudo"; exit 99',
                "flatpak": 'echo "UNEXPECTED flatpak"; exit 99',
                "pacman": 'echo "UNEXPECTED pacman"; exit 99',
            }
            for name, body in commands.items():
                executable = path / name
                executable.write_text("#!/bin/sh\n" + body + "\n")
                executable.chmod(0o755)
            return subprocess.run(
                ["just", *recipes],
                cwd=ROOT,
                env={
                    **os.environ,
                    "PATH": f"{path}:{os.environ['PATH']}",
                    "ROLE_DATA": json.dumps({"machineRole": role}),
                },
                capture_output=True,
                text=True,
                check=False,
            )

    def test_invalid_role_stops_package_commands(self):
        for recipe in ["pkg-apply", "pkg-fix", "flatpak-update"]:
            with self.subTest(recipe=recipe):
                result = self.invoke("invalid", recipe)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("UNEXPECTED", result.stdout)

    def test_bond_recipes_reject_non_corporate_roles(self):
        for role in ("host", "vm"):
            for recipe in (
                "canonical-bond-activate",
                "canonical-bond-keep",
                "canonical-bond-rollback",
            ):
                result = self.invoke(role, recipe)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("UNEXPECTED", result.stdout)
            result = self.invoke(role, "canonical-bond-prepare", "Wired connection 1")
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("UNEXPECTED", result.stdout)

    def test_non_host_maintenance_only_uses_chezmoi(self):
        for role in ["vm", "canonical"]:
            for recipe in ["diff", "merge", "re-add"]:
                with self.subTest(role=role, recipe=recipe):
                    result = self.invoke(role, recipe)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn("chezmoi", result.stdout)
                    self.assertNotIn("UNEXPECTED", result.stdout)

    def test_non_host_etc_paths_fail_before_home_changes(self):
        for recipe in ["diff", "merge", "re-add"]:
            result = self.invoke("canonical", recipe, ".config/zsh", "etc/hosts")
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("chezmoi", result.stdout)

    def test_vm_migration_initializes_role_before_switch(self):
        result = subprocess.check_output(
            ["just", "--justfile", "nix/justfile", "--dry-run", "migrate-chezmoi"],
            cwd=ROOT,
            stderr=subprocess.STDOUT,
            text=True,
        )
        self.assertLess(result.index("chezmoi init"), result.index("switch.sh"))

    def test_host_home_paths_do_not_select_etc(self):
        for recipe in ["diff", "merge", "re-add"]:
            result = self.invoke("host", recipe, ".config/zsh")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(len(result.stdout.splitlines()), 1)
            self.assertIn(".config/zsh", result.stdout)

    def test_host_mixed_paths_are_split_by_domain(self):
        for domain, expected in [("home", ".config/zsh"), ("etc", "etc/hosts")]:
            result = subprocess.check_output(
                [
                    "bash",
                    "-c",
                    (
                        "source scripts/maintenance-lib.sh; "
                        "_machine_role() { echo host; }; "
                        '_maintenance_select auto "$1" .config/zsh etc/hosts; '
                        'printf "%s\\n" "$maintenance_run" "${args[@]}"'
                    ),
                    "test",
                    domain,
                ],
                cwd=ROOT,
                text=True,
            )
            self.assertEqual(result.splitlines(), ["true", expected])
