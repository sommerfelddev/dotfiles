import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXTENSION = ROOT / "dot_local/share/gnome-shell/extensions/external-display@dotfiles"


class DisplayTests(unittest.TestCase):
    def test_metadata(self):
        metadata = json.loads((EXTENSION / "metadata.json").read_text())
        self.assertEqual(metadata["uuid"], "external-display@dotfiles")
        self.assertIn("50", metadata["shell-version"])

    def test_connection_changes_and_lifecycle(self):
        code = "\n".join(
            line
            for line in (EXTENSION / "extension.js").read_text().splitlines()
            if not line.startswith("import ")
        ).replace("export default class", "class")
        harness = (ROOT / "tests/fixtures/display-lifecycle.js").read_text()
        subprocess.run(
            ["node", "--input-type=module"],
            input=harness.replace("// EXTENSION", code),
            text=True,
            check=True,
        )
