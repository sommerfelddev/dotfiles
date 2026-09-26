import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXTENSION = ROOT / "dot_local/share/gnome-shell/extensions/workspace-cycle@dotfiles"


class WorkspaceCycleTests(unittest.TestCase):
    def test_schema_and_metadata(self):
        metadata = json.loads((EXTENSION / "metadata.json").read_text())
        self.assertEqual(metadata["uuid"], "workspace-cycle@dotfiles")
        self.assertEqual(metadata["shell-version"], ["50"])
        subprocess.run(
            [
                "glib-compile-schemas",
                "--strict",
                "--dry-run",
                str(EXTENSION / "schemas"),
            ],
            check=True,
        )

    def test_cycle_wraps_in_both_directions_and_releases_keys(self):
        source = "\n".join(
            line
            for line in (EXTENSION / "extension.js").read_text().splitlines()
            if not line.startswith("import ")
        )
        source = source.replace("export default class", "class")
        harness = (ROOT / "tests/fixtures/workspace-cycle.js").read_text()
        subprocess.run(
            ["node", "--input-type=module"],
            input=harness.replace("// EXTENSION", source),
            text=True,
            check=True,
        )
