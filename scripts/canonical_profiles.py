"""Add owned preferences to existing Snap browser profiles."""

import configparser
import json
import shutil
from pathlib import Path

from scripts.canonical import ROOT, require_canonical

START = "// dotfiles: begin"
END = "// dotfiles: end"


def preferences(existing: str, owned: str) -> str:
    if START in existing:
        before, remainder = existing.split(START, 1)
        if END not in remainder:
            raise ValueError("Incomplete dotfiles preference block")
        _, after = remainder.split(END, 1)
        existing = before.rstrip() + after
    return existing.rstrip() + "\n" + START + "\n" + owned.rstrip() + "\n" + END + "\n"


def profiles(root: Path) -> list[Path]:
    ini = configparser.ConfigParser(interpolation=None)
    ini.read(root / "profiles.ini")
    result = []
    for section in ini.sections():
        if not section.startswith("Profile") or "Path" not in ini[section]:
            continue
        path = Path(ini[section]["Path"])
        if ini[section].get("IsRelative", "1") == "1":
            path = root / path
        if path.resolve().is_relative_to(root.resolve()) and path.is_dir():
            result.append(path)
    return result


def deploy(root: Path, source: Path) -> None:
    found = profiles(root)
    if not found:
        print(f"No profile under {root}. Start the app once, close it, then retry.")
    for profile in found:
        target = profile / "user.js"
        existing = target.read_text() if target.exists() else ""
        updated = preferences(existing, source.read_text())
        if updated == existing:
            continue
        if target.exists() and not target.with_suffix(".js.pre-dotfiles").exists():
            shutil.copy2(target, target.with_suffix(".js.pre-dotfiles"))
        target.write_text(updated)
        print(f"Updated {target}")


def main() -> None:
    require_canonical()
    home = Path.home()
    deploy(home / "snap/firefox/common/.mozilla/firefox", ROOT / "canonical/firefox.js")
    deploy(
        home / "snap/thunderbird/common/.thunderbird", ROOT / "canonical/thunderbird.js"
    )
    source = (
        home
        / ".nix-profile/lib/mozilla/native-messaging-hosts/external_editor_revived.json"
    )
    manifest = json.loads(source.read_text())
    target = home / ".mozilla/native-messaging-hosts/external_editor_revived.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    manifest["path"] = str(home / ".nix-profile/bin/external-editor-revived")
    target.write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
