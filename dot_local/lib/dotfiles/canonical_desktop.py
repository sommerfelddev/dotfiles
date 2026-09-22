"""Apply owned GNOME keys and restore their previous values."""

import importlib
import json
import os
import shlex
import sys
from pathlib import Path

HOME = Path.home()
STATE = HOME / ".local/state/dotfiles/gnome-settings.json"
EXTENSIONS = [
    "external-display@dotfiles",
    "o-tiling@oliwebd.github.com",
    "copyous@boerdereinar.dev",
    "emoji-copy@felipeftn",
    "Vitals@CoreCoding.com",
    "ubuntu-appindicators@ubuntu.com",
]
DISABLED_EXTENSIONS = [
    "paperwm@paperwm.github.com",
    "ubuntu-dock@ubuntu.com",
    "tiling-assistant@ubuntu.com",
    "corporate-panel@dotfiles",
]


def save_state(saved: dict) -> None:
    STATE.parent.mkdir(parents=True, exist_ok=True)
    temporary = STATE.with_suffix(".tmp")
    temporary.write_text(json.dumps(saved, indent=2) + "\n")
    temporary.chmod(0o600)
    temporary.replace(STATE)


def settings_object(schema: str, path: str | None = None):
    gio = importlib.import_module("gi.repository.Gio")
    source = gio.SettingsSchemaSource.get_default()
    for directory in (HOME / ".local/share/gnome-shell/extensions").glob("*/schemas"):
        if (directory / "gschemas.compiled").exists():
            source = gio.SettingsSchemaSource.new_from_directory(
                str(directory), source, False
            )
    definition = source.lookup(schema, True)
    if definition is None:
        print(
            f"Missing schema: {schema}. Install extensions, log in again, then retry."
        )
        return None
    return gio.Settings.new_full(definition, None, path)


def write_key(
    schema: str, key: str, value, saved: dict, path: str | None = None
) -> None:
    settings = settings_object(schema, path)
    if settings is None:
        return
    if key not in settings.props.settings_schema.list_keys():
        raise RuntimeError(f"Unknown setting: {schema} {key}")
    if not settings.is_writable(key):
        print(f"Locked by policy: {schema} {key}")
        return
    glib = importlib.import_module("gi.repository.GLib")
    variant = glib.Variant(settings.get_value(key).get_type_string(), value)
    name = json.dumps([schema, key, path])
    if name not in saved:
        previous = settings.get_user_value(key)
        saved[name] = {
            "before": previous.print_(True) if previous is not None else None
        }
    saved[name]["applied"] = variant.print_(True)
    save_state(saved)
    if not settings.set_value(key, variant):
        raise RuntimeError(f"Cannot set {schema} {key}")


def merge_key(schema: str, key: str, values: list[str], saved: dict) -> None:
    settings = settings_object(schema)
    if settings is not None:
        write_key(
            schema, key, list(dict.fromkeys([*settings.get_strv(key), *values])), saved
        )


def shortcuts(saved: dict) -> None:
    display_schema = "org.gnome.mutter.keybindings"
    display_keys = settings_object(display_schema)
    if display_keys is not None:
        write_key(
            display_schema,
            "switch-monitor",
            [
                key
                for key in display_keys.get_strv("switch-monitor")
                if key != "<Super>p"
            ],
            saved,
        )
    shell = shlex.quote(str(HOME / ".nix-profile/bin/zsh"))
    actions = {
        "terminal": ("<Super>Return", "/snap/bin/ghostty"),
        "files": ("<Super><Shift>Return", f"/snap/bin/ghostty -e {shell} -lc yazi"),
        "browser": ("<Super><Shift>b", "/snap/bin/firefox"),
        "mail": ("<Super>t", "/snap/bin/thunderbird"),
        "dictate": ("<Super>i", f"{shell} -lc dictate"),
        "ocr": ("<Super><Shift>o", f"{shell} -lc ocr"),
        "record": ("<Super><Shift>r", f"{shell} -lc 'record toggle'"),
        "clipboard": (
            "<Super>p",
            "gdbus call --session --dest org.gnome.Shell.Extensions.Copyous --object-path /org/gnome/Shell/Extensions/Copyous --method org.gnome.Shell.Extensions.Copyous.Show",
        ),
    }
    schema = "org.gnome.settings-daemon.plugins.media-keys"
    paths = []
    for name, (binding, command) in actions.items():
        path = f"/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/dotfiles-{name}/"
        paths.append(path)
        for key, value in {
            "name": name,
            "binding": binding,
            "command": command,
        }.items():
            write_key(schema + ".custom-keybinding", key, value, saved, path)
    merge_key(schema, "custom-keybindings", paths, saved)


def extensions(saved: dict) -> None:
    schema = "org.gnome.shell"
    settings = settings_object(schema)
    if settings is None:
        return
    for key, added, removed in [
        ("enabled-extensions", EXTENSIONS, DISABLED_EXTENSIONS),
        ("disabled-extensions", DISABLED_EXTENSIONS, EXTENSIONS),
    ]:
        values = [value for value in settings.get_strv(key) if value not in removed]
        write_key(schema, key, list(dict.fromkeys([*values, *added])), saved)


def apply_settings(saved: dict) -> None:
    merge_key(
        "org.gnome.desktop.input-sources",
        "xkb-options",
        ["caps:escape", "compose:rctrl"],
        saved,
    )
    write_key(
        "org.gnome.desktop.input-sources", "sources", [("xkb", "us+altgr-intl")], saved
    )
    write_key("org.gnome.desktop.wm.keybindings", "close", ["<Super><Shift>q"], saved)
    write_key("org.gnome.desktop.wm.keybindings", "minimize", ["<Alt>F9"], saved)
    write_key(
        "org.gnome.shell.keybindings", "toggle-application-view", ["<Super>d"], saved
    )
    write_key(
        "org.gnome.desktop.wm.keybindings", "toggle-fullscreen", ["<Super>f"], saved
    )
    tiling(saved)
    shortcuts(saved)
    workspaces(saved)
    panel(saved)
    extensions(saved)


def tiling(saved: dict) -> None:
    schema = "org.gnome.shell.extensions.o-tiling"
    for key, value in {
        "tile-by-default": True,
        "new-window-placement": "focused",
        "active-hint-overlay-enabled": False,
        "workspace-switcher-style": False,
        "workspace-number-indicator": True,
        "panel-transparency": False,
        "mouse-cursor-follows-active-window": False,
        "toggle-floating": ["<Super><Shift>space"],
    }.items():
        write_key(schema, key, value, saved)
    for key in [
        "tile-enter",
        "toggle-tiling",
        "tile-orientation",
        "pop-workspace-up",
        "pop-workspace-down",
    ]:
        write_key(schema, key, [], saved)
    for direction, letter in zip(["left", "down", "up", "right"], "hjkl"):
        binding = "<Super>Right" if direction == "right" else f"<Super>{letter}"
        write_key(schema, f"focus-{direction}", [binding], saved)
        write_key(
            schema, f"tile-move-{direction}-global", [f"<Super><Shift>{letter}"], saved
        )


def panel(saved: dict) -> None:
    emoji = "org.gnome.shell.extensions.emoji-copy"
    write_key(emoji, "always-show", False, saved)
    write_key(emoji, "active-keybind", True, saved)
    write_key(emoji, "emoji-keybind", ["<Super>period"], saved)
    schema = "org.gnome.shell.extensions.vitals"
    monitor = shlex.join(
        ["/snap/bin/ghostty", "-e", str(HOME / ".nix-profile/bin/htop")]
    )
    for key, value in {
        "hot-sensors": [
            "_processor_usage_",
            "__temperature_max__",
            "_memory_usage_",
            "__network-rx_max__",
            "__network-tx_max__",
        ],
        "position-in-panel": 2,
        "update-time": 5,
        "include-public-ip": False,
        "monitor-cmd": monitor,
    }.items():
        write_key(schema, key, value, saved)
    write_key("org.gnome.desktop.interface", "show-battery-percentage", True, saved)
    write_key("org.gnome.desktop.interface", "clock-show-weekday", True, saved)


def workspaces(saved: dict) -> None:
    write_key("org.gnome.mutter", "dynamic-workspaces", True, saved)
    for number in range(1, 11):
        key = str(number % 10)
        for action, modifier in [("switch", ""), ("move", "<Shift>")]:
            write_key(
                "org.gnome.desktop.wm.keybindings",
                f"{action}-to-workspace-{number}",
                [f"<Super>{modifier}{key}"],
                saved,
            )
        if number < 10:
            write_key(
                "org.gnome.shell.keybindings",
                f"switch-to-application-{number}",
                [],
                saved,
            )


def restore(saved: dict) -> None:
    glib = importlib.import_module("gi.repository.GLib")
    for name, entry in list(saved.items()):
        schema, key, path = json.loads(name)
        settings = settings_object(schema, path)
        if settings is None or not settings.is_writable(key):
            continue
        if settings.get_value(key).print_(True) != entry["applied"]:
            print(f"Changed since deployment; retained: {schema} {key}")
            continue
        if entry["before"] is None:
            settings.reset(key)
        else:
            settings.set_value(
                key, glib.Variant.parse(None, entry["before"], None, None)
            )
        del saved[name]
    save_state(saved)


def main() -> None:
    if (HOME / ".config/dotfiles/role").read_text().strip() != "canonical":
        raise SystemExit("The desktop settings require the canonical role.")
    if "GNOME" not in os.environ.get("XDG_CURRENT_DESKTOP", "").upper():
        raise SystemExit("Run this command from the GNOME desktop session.")
    saved = json.loads(STATE.read_text()) if STATE.exists() else {}
    if sys.argv[1:] == ["settings"]:
        apply_settings(saved)
    elif sys.argv[1:] == ["restore"]:
        restore(saved)
    else:
        raise SystemExit("Use settings or restore.")
    importlib.import_module("gi.repository.Gio").Settings.sync()


if __name__ == "__main__":
    main()
