"""Permit the Mattermost Snap to use the desktop keyring and tray."""

import os
import re
import subprocess
import tempfile
from pathlib import Path

PROFILE = Path(
    "/var/lib/snapd/apparmor/profiles/snap.mattermost-desktop.mattermost-desktop"
)
MARKER = "# dotfiles: Mattermost Secret Service access"
RULES = """
dbus (receive, send)
    bus=session
    path=/org/freedesktop/secrets{,/**}
    interface=org.freedesktop.DBus.*
    peer=(label=unconfined),
dbus (receive, send)
    bus=session
    path=/org/freedesktop/secrets{,/**}
    interface=org.freedesktop.Secret.{Collection,Item,Prompt,Service,Session}
    peer=(label=unconfined),
"""
TRAY_MARKER = "# dotfiles: Mattermost Chromium tray access"
TRAY_RULES = """
dbus (receive)
    bus=session
    path=/org/chromium/StatusNotifierItem/[0-9]*
    interface=org.freedesktop.DBus.Properties
    member=Get{,All}
    peer=(label=unconfined),
dbus (send)
    bus=session
    path=/org/chromium/StatusNotifierItem/[0-9]*
    interface=org.freedesktop.DBus.Properties
    member=PropertiesChanged
    peer=(label=unconfined),
dbus (send)
    bus=session
    path=/org/chromium/StatusNotifierItem/[0-9]*
    interface=org.kde.StatusNotifierItem
    member=New*
    peer=(label=unconfined),
dbus (receive)
    bus=session
    path=/org/chromium/StatusNotifierItem/[0-9]*
    interface=org.kde.StatusNotifierItem
    member={Activate,ContextMenu,Scroll,SecondaryActivate,ProvideXdgActivationToken,XAyatanaSecondaryActivate}
    peer=(label=unconfined),
dbus (send)
    bus=session
    path=/org/chromium/DbusMenu{,/[0-9]*}
    interface=com.canonical.dbusmenu
    member={LayoutUpdated,ItemsPropertiesUpdated}
    peer=(label=unconfined),
dbus (receive)
    bus=session
    path=/org/chromium/DbusMenu{,/[0-9]*}
    interface={org.freedesktop.DBus.Properties,com.canonical.dbusmenu}
    member={Get*,AboutTo*,Event*}
    peer=(label=unconfined),
"""


def patch_profile(text: str) -> str:
    profiles = re.findall(r'^profile "([^"]+)"', text, re.MULTILINE)
    if profiles != [PROFILE.name] or not text.rstrip().endswith("}"):
        raise ValueError("Unexpected Mattermost AppArmor profile format.")
    for marker, rules in [(MARKER, RULES), (TRAY_MARKER, TRAY_RULES)]:
        if marker not in text:
            text = text.rstrip()[:-1] + marker + "\n" + rules + "}\n"
    return text


def install_profile(text: str) -> None:
    with tempfile.TemporaryDirectory(dir=PROFILE.parent) as directory:
        target = Path(directory) / PROFILE.name
        target.write_text(text)
        subprocess.run(
            ["apparmor_parser", "--skip-kernel-load", "--skip-cache", str(target)],
            check=True,
        )
        target.chmod(PROFILE.stat().st_mode & 0o777)
        os.replace(target, PROFILE)


def main() -> None:
    if os.geteuid() != 0:
        raise SystemExit("Run this command as root.")
    original = PROFILE.read_text()
    patched = patch_profile(original)
    if patched != original:
        install_profile(patched)
    subprocess.run(
        ["apparmor_parser", "--replace", "--skip-cache", str(PROFILE)], check=True
    )


if __name__ == "__main__":
    main()
