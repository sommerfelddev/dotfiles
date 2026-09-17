# Canonical Laptop

Target: Ubuntu 26.04 LTS on the company ThinkPad T14 Gen 6, with GNOME/GDM.
Use the `canonical` role. Do not use the Arch bootstrap or the old VM bootstrap.

## Company Provisioning

1. Download the current LTS image from [Ubuntu](https://ubuntu.com/download/desktop).
2. [Verify the image](https://ubuntu.com/tutorials/how-to-verify-ubuntu#1-overview)
   and [make the USB installer](https://documentation.ubuntu.com/desktop/en/latest/how-to/create-a-bootable-usb-stick/).
3. Use the current corporate autoinstall file from the internal guide. Do not
   put that file, its registration key, or company credentials in this repo.
4. Select encrypted storage **with LVM**. Use different passwords for disk
   encryption and login. Verify both choices before starting installation.
5. Complete Landscape registration with the temporary account, as instructed
   by the company. Reboot and log in through Google/authd with the final work
   account. Wait for provisioning and sudo access to complete.
6. Set the time zone to Europe/Lisbon. Confirm registration:

   ```sh
   sudo landscape-config --actively-registered
   ```

Do all remaining steps as the **final work account**, without a root shell.
Do not change its login shell. Do not disable company lock, suspend, AppArmor,
network, update, or account policies. This repo does not own those policies.

## Install Nix and Get the Repo

Install [upstream multi-user Nix](https://nixos.org/download/):

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh -s -- --daemon
```

Open a new terminal. Check `nix --version`. If Nix is already installed, inspect
its owner first; do not run another installer over it.

```sh
sudo apt-get update
sudo apt-get install git
git clone https://github.com/sommerfelddev/dotfiles "$HOME/dotfiles"
cd "$HOME/dotfiles"
nix --extra-experimental-features 'nix-command flakes' develop ./nix
CHEZMOI_MACHINE_ROLE=canonical chezmoi init -S .
```

Enter your work name, Canonical email, and full work GPG signing fingerprint.
These values stay in the local chezmoi config. Check that `chezmoi data` reports
`machineRole` as `canonical`. Do not accept `host` or `vm` for this laptop.

## Deploy

Run these commands on the laptop, not inside aibox:

```sh
just test
just canonical-setup
```

This installs declared packages, builds the locked Home-Manager profile,
deploys the corporate home files, loads two program-specific AppArmor profiles,
connects Thunderbird's GPG interface, and installs the GNOME extensions.
It does not remove packages or switch to another source when installation fails.

Log out and back in through GDM. Then run:

```sh
cd "$HOME/dotfiles"
just canonical-desktop
just canonical-check
```

The extension schemas can be unavailable until the first new login. Repeat
`canonical-desktop` after that login if it reported missing schemas. Keep Ubuntu
AppIndicator enabled for tray icons. Disable Ubuntu Tiling Assistant in the
Extensions app if it conflicts with PaperWM. Do not override a policy lock.

Ghostty starts Nix zsh as a login shell. It does not change the authd account's
shell. GNOME keeps its own desktop environment and GNOME Keyring. `pass` remains
a terminal tool; this role does not install the pass Secret Service daemon.

## Package Sources

| Source         | Applications                                                                     |
| -------------- | -------------------------------------------------------------------------------- |
| Snap, stable   | Firefox, Thunderbird, Ghostty, Mattermost, Zoom, Okular, LibreOffice, Keybase    |
| Flatpak, user  | Nheko work profile, Zathura, NormCap, GPU Screen Recorder                        |
| Nix            | Shared CLI and AI tools, Neovim, zsh, Podman, GPG, desktop helper commands       |
| apt exceptions | Git, Flatpak, uidmap, Copyous libraries, zbar-tools, pinentry-gnome3, python3-gi |

The lists are in `meta/canonical/`. Ghostty's classic confinement is explicit.
The stable Keybase GUI has an old Electron dependency; its risk was accepted
for this setup. Installing the Snap does not remove that risk.
The Snap package also starts Electron with its internal sandbox disabled.
Snap confinement is a separate layer.

## Work Keys and Containers

Transfer and import only the existing **work** secret key through a protected
channel. Do not copy personal or former-employer keyrings. Check:

```sh
gpg --list-secret-keys --with-keygrip
gpg --export-ssh-key YOUR_WORK_FINGERPRINT
gpg-connect-agent 'keyinfo --list' /bye
ssh-add -L
git var GIT_AUTHOR_IDENT
```

Add the work authentication subkey's keygrip to the local `~/.gnupg/sshcontrol`
if it is not exposed by the agent. That file is not deployed by this role.
Use `~/.ssh/config.local` for work host rules. Register the public key with the
required services. Do not enable agent forwarding.

The Nix agent uses Ubuntu's user sockets and graphical pinentry. Log out and
back in after the first deployment so an older agent does not remain active.
Test one signed Git commit and one SSH connection before moving work to this
machine. Do not expose the private key or full agent logs in support requests.

Rootless Podman needs subordinate UID and GID ranges for the final authd user:

```sh
getsubids "$USER"
getsubids -g "$USER"
podman info
podman run --rm docker.io/library/alpine:latest id
```

If either range is missing, have a free, non-overlapping range assigned through
the system's account administration method. Do not copy another user's ranges
or assume that an authd user can be changed with `usermod`. The setup does not
rewrite `/etc/subuid`, `/etc/subgid`, or company account data.

The repo loads only `dotfiles-nix-bwrap` and `dotfiles-nix-podman` AppArmor
profiles. Global user-namespace restrictions stay enabled. Test `aibox -p` and
a rootless container. If AppArmor denies another executable, inspect the exact
denial before adding a rule. Do not allow every program under `/nix/store`.

## Browser and Mail

Start Firefox and Thunderbird once, then close them. Run:

```sh
just canonical-profiles
```

This discovers profiles from each Snap's `profiles.ini`, saves an initial
`user.js.pre-dotfiles` backup, and replaces only the marked preference block.
It keeps existing preferences outside that block. New profiles need another
run. The personal Arkenfox profile, accounts, passwords, and Thunderbird cache
are not imported.

Add work accounts through the applications. Thunderbird autostarts as a normal
window; there is no scratchpad or Birdtray. Enable system notifications in its
settings and test a message from a different account.

For external GPG, `canonical-system` connects `thunderbird:gpg-keys` and the
managed preferences enable external GnuPG. Select the external work key in
Thunderbird's account settings. Test signing and decryption.

For Neovim compose, install External Editor Revived from Thunderbird Add-ons.
`canonical-profiles` installs the host native-messaging manifest for the Nix
helper. The Ubuntu Thunderbird Snap supplies native-messaging portal support.
Approve the portal prompt. Configure the add-on's custom editor to start a
separate Ghostty process, run Nix Neovim on its supplied file, and wait for exit.
Use the add-on's file placeholder, not a fixed draft filename. Disable Ghostty
single-instance reuse for this command (`--gtk-single-instance=false`). Test
that closing Neovim returns the text to the draft. Do not use a Flatpak host
wrapper or grant access to the full home directory to fix a failed test.

PDF files use Zathura. Test a PDF attachment with spaces and accented letters
in its name. Okular is also available. Re-select Zathura in the application
chooser if an old portal choice overrides the default.

## Desktop Checks

Mattermost, Keybase, Thunderbird, and one Nheko `work` profile autostart through
GNOME. In Nheko, enable its tray and start-in-tray options for that profile.
Disable duplicate application-owned autostart entries. Test notifications with
another account, not a message to yourself.

The managed shortcuts are listed in `KEYBINDS.md`. Settings are reapplied by
`just apply` in GNOME. Policy-locked keys are reported and skipped. Only touched
keys are saved in `~/.local/state/dotfiles/gnome-settings.json`.

```sh
just canonical-desktop-restore
```

Restore skips keys changed since deployment. It does not reset all of dconf.

Check these operations both docked and undocked:

- PaperWM focus, window movement, terminal and browser launch.
- Lock, unlock, suspend, resume, lid state, and external monitors.
- HP webcam selection with `rqr`; the integrated camera when undocked.
- A Google Meet camera, microphone, speaker, and screen-share session.
- `ocr` with NormCap and `ocr image.png` with Tesseract. Add English and
  Portuguese recognition data in NormCap's settings.
- `dictate` twice: start recording, then transcribe to the clipboard. Paste
  manually. GNOME does not use the Sway `wtype` path.
- `record start`, portal selection, `record status`, then `record stop`.
  Check the output in `~/vids`. Also test cancellation of the portal prompt.
- `wqr`, Copyous history, and Emoji Copy.

No existing laptop camera IDs, udev rules, firewall rules, power workarounds,
or dock settings are copied to this machine.

## Updates and Rollback

`just update` upgrades apt packages, refreshes Snaps without overriding holds,
updates declared Flatpaks, refreshes Nix inputs and release locks, updates
Neovim, and updates the declared extensions. It does not run apt autoremove or
dist-upgrade. Snap refresh also covers other installed Snaps; snapd still owns
automatic refresh and company controls.

Use `just nix-daemon-update` separately for the upstream Nix engine. It updates
the root-owned default Nix profile, not the Home-Manager package inputs. Nix
database changes can make an engine downgrade unsafe; consult the upstream
upgrade instructions before downgrading.

Keep the previous Home-Manager generation until the new one passes the checks.
Use `home-manager generations` to find its activation path. Restore GNOME keys
with the recipe above. Remove only the `dotfiles-*` XDG autostart entries to
stop repo-owned startup. Do not remove company software during rollback.

## Validation Boundary

`just test` checks package commands, template identities, and role file
boundaries. CI also checks formatting, lint, and Nix profile evaluation. These
checks do not prove that Snap portals, the dock, authd, or GNOME extensions work
on the real laptop. Complete the desktop checks after provisioning before
depending on this machine for meetings.
