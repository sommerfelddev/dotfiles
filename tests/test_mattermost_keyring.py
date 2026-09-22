import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts import mattermost_keyring


class MattermostKeyringTests(unittest.TestCase):
    def test_adds_tray_rules_to_existing_keyring_patch(self):
        original = (
            'profile "snap.mattermost-desktop.mattermost-desktop" {\n'
            + mattermost_keyring.MARKER
            + "\n"
            + mattermost_keyring.RULES
            + "}\n"
        )
        patched = mattermost_keyring.patch_profile(original)
        self.assertIn("path=/org/chromium/StatusNotifierItem/[0-9]*", patched)
        self.assertIn("interface=org.kde.StatusNotifierItem", patched)
        self.assertIn("path=/org/chromium/DbusMenu{,/[0-9]*}", patched)
        self.assertEqual(patched.count(mattermost_keyring.MARKER), 1)
        self.assertEqual(mattermost_keyring.patch_profile(patched), patched)
        self.assertNotIn("IdleMonitor", patched)
        self.assertNotIn("smaps_rollup", patched)

    def test_adds_rules_only_once(self):
        original = 'profile "snap.mattermost-desktop.mattermost-desktop" {\n}\n'
        patched = mattermost_keyring.patch_profile(original)
        self.assertIn("interface=org.freedesktop.Secret.", patched)
        self.assertEqual(mattermost_keyring.patch_profile(patched), patched)

    def test_rejects_other_profiles(self):
        with self.assertRaises(ValueError):
            mattermost_keyring.patch_profile('profile "snap.other" {\n}\n')

    def test_rejects_incomplete_profile(self):
        with self.assertRaises(ValueError):
            mattermost_keyring.patch_profile(
                'profile "snap.mattermost-desktop.mattermost-desktop" {\n'
            )

    def test_rejects_multiple_profiles(self):
        with self.assertRaises(ValueError):
            mattermost_keyring.patch_profile(
                'profile "snap.mattermost-desktop.mattermost-desktop" {\n}\n'
                'profile "snap.other" {\n}\n'
            )

    def test_preserves_snap_permissions(self):
        original = (
            'profile "snap.mattermost-desktop.mattermost-desktop" '
            "flags=(attach_disconnected,mediate_deleted) {\n  /example r,\n}\n"
        )
        patched = mattermost_keyring.patch_profile(original)
        self.assertTrue(patched.startswith(original[:-2]))
        self.assertNotIn("kwallet", patched)
        self.assertNotIn("complain", patched)

    def test_parser_failure_leaves_installed_profile_unchanged(self):
        with tempfile.TemporaryDirectory() as directory:
            profile = Path(directory) / mattermost_keyring.PROFILE.name
            profile.write_text("original")
            with (
                patch.object(mattermost_keyring, "PROFILE", profile),
                patch.object(
                    mattermost_keyring.subprocess,
                    "run",
                    side_effect=subprocess.CalledProcessError(1, "apparmor_parser"),
                ),
                self.assertRaises(subprocess.CalledProcessError),
            ):
                mattermost_keyring.install_profile("invalid")
            self.assertEqual(profile.read_text(), "original")
            self.assertEqual(list(Path(directory).iterdir()), [profile])
