import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location(
    "desktop", ROOT / "dot_local/lib/dotfiles/canonical_desktop.py"
)
assert SPEC and SPEC.loader
desktop = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(desktop)


class DesktopTests(unittest.TestCase):
    def test_extensions_replace_tiler_and_hide_dock_and_status(self):
        settings = MagicMock()
        settings.get_strv.side_effect = [
            ["company", "paperwm@paperwm.github.com", "corporate-panel@dotfiles"],
            ["unrelated", "o-tiling@oliwebd.github.com"],
        ]
        with (
            patch.object(desktop, "settings_object", return_value=settings),
            patch.object(desktop, "write_key") as write,
        ):
            desktop.extensions({})
        write.assert_any_call(
            "org.gnome.shell",
            "enabled-extensions",
            ["company", *desktop.EXTENSIONS],
            {},
        )
        write.assert_any_call(
            "org.gnome.shell",
            "disabled-extensions",
            ["unrelated", *desktop.DISABLED_EXTENSIONS],
            {},
        )

    def test_tiling_shortcuts_do_not_claim_application_keys(self):
        with patch.object(desktop, "write_key") as write:
            desktop.tiling({})
        schema = "org.gnome.shell.extensions.o-tiling"
        for key in [
            "tile-enter",
            "toggle-tiling",
            "tile-orientation",
            "pop-workspace-up",
            "pop-workspace-down",
        ]:
            write.assert_any_call(schema, key, [], {})
        write.assert_any_call(schema, "new-window-placement", "focused", {})
        write.assert_any_call(schema, "focus-right", ["<Super>Right"], {})
        write.assert_any_call(schema, "tile-move-down-global", ["<Super><Shift>j"], {})

    def test_clipboard_shortcut_preserves_other_display_bindings(self):
        settings = MagicMock()
        settings.get_strv.return_value = ["<Super>p", "XF86Display", "<Super>x"]
        with (
            patch.object(desktop, "settings_object", return_value=settings),
            patch.object(desktop, "write_key") as write,
        ):
            desktop.shortcuts({})
        write.assert_any_call(
            "org.gnome.mutter.keybindings",
            "switch-monitor",
            ["XF86Display", "<Super>x"],
            {},
        )

    def test_panel_settings_disable_external_ip_lookup(self):
        with patch.object(desktop, "write_key") as write:
            desktop.panel({})
        write.assert_any_call(
            "org.gnome.shell.extensions.vitals", "include-public-ip", False, {}
        )
        self.assertNotIn("corporate-panel@dotfiles", desktop.EXTENSIONS)
        self.assertIn("ubuntu-appindicators@ubuntu.com", desktop.EXTENSIONS)
        write.assert_any_call(
            "org.gnome.shell.extensions.emoji-copy", "always-show", False, {}
        )

    def test_unknown_keys_fail_without_writing(self):
        settings = MagicMock()
        settings.props.settings_schema.list_keys.return_value = []
        with (
            patch.object(desktop, "settings_object", return_value=settings),
            self.assertRaisesRegex(RuntimeError, "Unknown setting"),
        ):
            desktop.write_key("schema", "missing", "value", {})
        settings.set_value.assert_not_called()

    def test_launcher_uses_gnome_application_view_key(self):
        with (
            patch.object(desktop, "extensions"),
            patch.object(desktop, "merge_key"),
            patch.object(desktop, "shortcuts"),
            patch.object(desktop, "workspaces"),
            patch.object(desktop, "write_key") as write,
        ):
            desktop.apply_settings({})
        write.assert_any_call(
            "org.gnome.shell.keybindings", "toggle-application-view", ["<Super>d"], {}
        )

    def test_locked_keys_are_never_written(self):
        settings = MagicMock()
        settings.props.settings_schema.list_keys.return_value = ["key"]
        settings.is_writable.return_value = False
        with patch.object(desktop, "settings_object", return_value=settings):
            desktop.write_key("schema", "key", "value", {})
        settings.set_value.assert_not_called()

    def test_first_snapshot_is_kept_on_repeated_apply(self):
        settings = MagicMock()
        settings.props.settings_schema.list_keys.return_value = ["key"]
        settings.get_user_value.return_value.print_.return_value = "'original'"
        glib = MagicMock()
        glib.Variant.return_value.print_.return_value = "'managed'"
        saved = {}
        with (
            tempfile.TemporaryDirectory() as directory,
            patch.object(desktop, "STATE", Path(directory) / "state.json"),
            patch.object(desktop, "settings_object", return_value=settings),
            patch.object(desktop.importlib, "import_module", return_value=glib),
        ):
            desktop.write_key("schema", "key", "managed", saved)
            settings.get_user_value.return_value.print_.return_value = "'changed'"
            desktop.write_key("schema", "key", "managed", saved)
        self.assertEqual(next(iter(saved.values()))["before"], "'original'")

    def test_merge_keeps_unrelated_entries(self):
        settings = MagicMock()
        settings.get_strv.return_value = ["company", "personal"]
        with (
            patch.object(desktop, "settings_object", return_value=settings),
            patch.object(desktop, "write_key") as write,
        ):
            desktop.merge_key("schema", "key", ["personal", "new"], {})
        write.assert_called_once_with(
            "schema", "key", ["company", "personal", "new"], {}
        )


if __name__ == "__main__":
    unittest.main()
