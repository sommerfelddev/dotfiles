import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


class CrateFetchTests(unittest.TestCase):
    def test_checkout_path_with_special_characters(self):
        attrs = {"url": "https://example.org/source.tar.gz", "hash": "unchanged"}
        with tempfile.TemporaryDirectory() as directory:
            checkout = Path(directory) / 'rui@canonical.com space " ${name}'
            checkout.mkdir()
            (checkout / "nix").symlink_to(ROOT / "nix", target_is_directory=True)
            with patch(f"{__name__}.ROOT", checkout):
                self.assertEqual(self.evaluate(attrs), attrs)

    def evaluate(self, attrs):
        expression = (
            'let fetch = import (builtins.toPath (builtins.getEnv "CRATE_TEST_SOURCE")) (args: args); '
            'in fetch (builtins.fromJSON (builtins.getEnv "CRATE_TEST_ATTRS"))'
        )
        return json.loads(
            subprocess.check_output(
                ["nix", "eval", "--impure", "--json", "--expr", expression],
                text=True,
                env={
                    **os.environ,
                    "CRATE_TEST_SOURCE": str(ROOT / "nix/fetch-crate.nix"),
                    "CRATE_TEST_ATTRS": json.dumps(attrs),
                },
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
