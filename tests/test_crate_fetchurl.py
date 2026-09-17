import json
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class CrateFetchTests(unittest.TestCase):
    def evaluate(self, attrs):
        expression = (
            f"let fetch = import {ROOT}/nix/fetch-crate.nix (args: args); "
            f"in fetch (builtins.fromJSON {json.dumps(json.dumps(attrs))})"
        )
        return json.loads(
            subprocess.check_output(
                ["nix", "eval", "--impure", "--json", "--expr", expression], text=True
            )
        )

    def test_crate_uses_static_archive_and_keeps_hash(self):
        attrs = {
            "name": "download-hashbrown-0.16.1",
            "url": "https://crates.io/api/v1/crates/hashbrown/0.16.1/download",
            "sha256": "locked-checksum",
        }
        self.assertEqual(
            self.evaluate(attrs),
            {
                **attrs,
                "url": "https://static.crates.io/crates/hashbrown/hashbrown-0.16.1.crate",
            },
        )

    def test_other_downloads_are_unchanged(self):
        attrs = {"url": "https://example.org/source.tar.gz", "hash": "unchanged"}
        self.assertEqual(self.evaluate(attrs), attrs)

    def test_url_lists_are_unchanged(self):
        attrs = {"urls": ["https://example.org/source.tar.gz"], "hash": "unchanged"}
        self.assertEqual(self.evaluate(attrs), attrs)
