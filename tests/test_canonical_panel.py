import importlib.util
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "panel", ROOT / "dot_local/lib/dotfiles/canonical_panel.py"
)
assert SPEC and SPEC.loader
panel = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(panel)


class PanelTests(unittest.TestCase):
    def test_extension_lifecycle(self):
        source = (
            ROOT
            / "dot_local/share/gnome-shell/extensions/corporate-panel@dotfiles/extension.js"
        )
        code = "\n".join(
            line
            for line in source.read_text().splitlines()
            if not line.startswith("import ")
        )
        code = code.replace("export default class", "class")
        harness = (ROOT / "tests/fixtures/panel-lifecycle.js").read_text()
        subprocess.run(
            ["node", "--input-type=module"],
            input=harness.replace("// EXTENSION", code),
            text=True,
            check=True,
        )

    def test_failed_units_use_both_scopes(self):
        with patch.object(
            panel, "output", side_effect=['[{"unit":"a.service"}]', "[]"]
        ):
            self.assertEqual(panel.failed_units(), "FAIL 1")

    def test_failed_query_does_not_report_healthy(self):
        with patch.object(panel, "output", side_effect=RuntimeError("offline")):
            status = panel.collect()
        self.assertEqual(status["failed"], "FAIL ?")
        self.assertIn("offline", status["errors"])

    def test_updates_ignore_header(self):
        with patch.object(
            panel,
            "output",
            return_value="Listing...\na/stable 1 amd64 [upgradable from: 0]\n",
        ):
            self.assertEqual(panel.apt_updates(), "APT 1")

    def test_displays_do_not_depend_on_personal_connector_names(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, value in [
                ("card1-DP-9", "connected"),
                ("card0-eDP-1", "connected"),
                ("card1-HDMI-A-1", "disconnected"),
            ]:
                (root / name).mkdir()
                (root / name / "status").write_text(value)
            self.assertEqual(panel.displays(root), "EXT 1")

    def test_update_action_quotes_source_directory(self):
        with patch.object(panel, "output", return_value="/tmp/work tree'quoted\n"):
            command = panel.action_command("update")
        self.assertEqual(command[:2], ["/snap/bin/ghostty", "-e"])
        self.assertIn("just update", command[-1])
        self.assertIn("'\"'\"'", command[-1])

    def test_extension_metadata_targets_corporate_gnome(self):
        metadata = json.loads(
            (
                ROOT
                / "dot_local/share/gnome-shell/extensions/corporate-panel@dotfiles/metadata.json"
            ).read_text()
        )
        self.assertEqual(metadata["uuid"], "corporate-panel@dotfiles")
        self.assertIn("50", metadata["shell-version"])


if __name__ == "__main__":
    unittest.main()
