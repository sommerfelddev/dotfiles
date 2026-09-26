import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class HostAutostartTests(unittest.TestCase):
    def test_work_chat_is_not_started_by_sway(self):
        units = (ROOT / "systemd-units/user.txt").read_text()
        target = (ROOT / "dot_config/systemd/user/sway-session.target").read_text()
        for content in (units, target):
            self.assertNotIn("mattermost.service", content)
            self.assertNotIn("nheko@work.service", content)
            self.assertIn("nheko@personal.service", content)
        self.assertTrue((ROOT / "dot_config/systemd/user/mattermost.service").exists())
        for app in ("mattermost", "nheko"):
            self.assertTrue(
                (ROOT / f"dot_config/autostart/dotfiles-{app}.desktop").exists()
            )
