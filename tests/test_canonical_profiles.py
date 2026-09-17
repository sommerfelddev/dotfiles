import tempfile
import unittest
from pathlib import Path

from scripts.canonical_profiles import preferences, profiles


class ProfileTests(unittest.TestCase):
    def test_preferences_preserve_user_lines_and_are_idempotent(self):
        original = 'user_pref("local.setting", true);\n'
        owned = 'user_pref("mail.biff.show_alert", true);\n'
        result = preferences(original, owned)
        self.assertIn(original, result)
        self.assertEqual(preferences(result, owned), result)
        self.assertNotIn("show_alert", preferences(result, ""))

    def test_incomplete_marker_is_not_overwritten(self):
        with self.assertRaises(ValueError):
            preferences("// dotfiles: begin\nlocal data", "")

    def test_profile_paths_stay_inside_the_snap_directory(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "work@canonical.com").mkdir()
            (root / "profiles.ini").write_text(
                "[Profile0]\nPath=work@canonical.com\nIsRelative=1\n"
                "[Profile1]\nPath=/etc\nIsRelative=0\n"
            )
            self.assertEqual(profiles(root), [root / "work@canonical.com"])


if __name__ == "__main__":
    unittest.main()
