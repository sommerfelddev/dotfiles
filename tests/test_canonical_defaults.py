import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def chezmoi(role, *args):
    return subprocess.check_output(
        [
            "chezmoi",
            "--config",
            "/dev/null",
            "--config-format",
            "toml",
            "--override-data",
            json.dumps({"machineRole": role}),
            "-S",
            str(ROOT),
            *args,
        ],
        text=True,
    )


class DefaultTests(unittest.TestCase):
    def test_corporate_defaults_use_managed_launchers(self):
        rendered = chezmoi(
            "canonical",
            "execute-template",
            "--file",
            str(ROOT / "dot_config/mimeapps.list.tmpl"),
        )
        for value in (
            "inode/directory=dotfiles-yazi.desktop",
            "text/plain=dotfiles-nvim.desktop",
            "image/png=imv.desktop",
            "application/pdf=org.pwmt.zathura.desktop",
        ):
            self.assertIn(value, rendered)

    def test_launchers_are_corporate_only_and_use_ghostty(self):
        for role in ("host", "vm", "canonical"):
            files = chezmoi(role, "managed", "--include=files").splitlines()
            for app in ("yazi", "nvim"):
                target = f".local/share/applications/dotfiles-{app}.desktop"
                self.assertEqual(target in files, role == "canonical")
                entry = chezmoi(
                    role,
                    "execute-template",
                    "--file",
                    str(
                        ROOT
                        / f"dot_local/share/applications/dotfiles-{app}.desktop.tmpl"
                    ),
                )
                self.assertIn("Exec=/snap/bin/ghostty -e ", entry)
                self.assertIn(f'/.nix-profile/bin/{app}"', entry)
                self.assertIn("Terminal=false", entry)
