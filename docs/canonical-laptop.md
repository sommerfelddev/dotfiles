# Canonical Laptop

Target: Ubuntu 26.04 LTS on the company ThinkPad T14 Gen 6, with GNOME/GDM.
Use the `canonical` role. Do not use the Arch bootstrap or the old VM bootstrap.

## Company Provisioning

1. Download the current LTS image from [Ubuntu](https://ubuntu.com/download/desktop).
2. [Verify the image](https://ubuntu.com/tutorials/how-to-verify-ubuntu#1-overview)
   and [make the USB installer](https://documentation.ubuntu.com/desktop/en/latest/how-to/create-a-bootable-usb-stick/).
3. Use the current corporate autoinstall file from the internal guide. Do not
   put that file, its registration key, or company credentials in this repo.
   Use the [SSH transfer steps](#transfer-the-autoinstall-file) below to send
   it from your personal laptop to the live Ubuntu desktop.
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

## Transfer the Autoinstall File

On your personal laptop, download the current corporate `autoinstall.yaml`
from Canonical's Google Drive through the internal setup guide. Keep it outside
this repo. Do not use `tmp/canonical-vm/media/autoinstall.yaml`: that file is
for the disposable test VM and does not provision a company laptop.

Boot the original Ubuntu USB installer and connect to a trusted LAN. Update
the installer if offered, then close it without starting the installation.
Open a terminal in the live Ubuntu desktop and run:

```sh
whoami
sudo passwd ubuntu
sudo apt update
sudo apt install openssh-server
sudo systemctl start ssh
hostname -I
sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

These commands assume `whoami` prints `ubuntu`. If it differs, use that name
in the password command, transfer command, and home path below. Set a strong
temporary password. Use the live session's LAN IP address for the transfer.

On your personal laptop, run this with the actual source path and IP address:

```sh
scp /path/to/autoinstall.yaml ubuntu@<live-session-IP>:/home/ubuntu/autoinstall.yaml
```

Check that the SSH host-key fingerprint matches the one displayed in the live
session before accepting it. Enter the temporary password. In the live session:

```sh
chmod 600 ~/autoinstall.yaml
sudo systemctl stop ssh.socket ssh.service
```

Reopen **Install Ubuntu**, select **Automated with autoinstall file**, and use
**Browse** to select `/home/ubuntu/autoinstall.yaml`, or enter:

```text
file:///home/ubuntu/autoinstall.yaml
```

Click **Import**. Continue with encrypted LVM and the company provisioning steps
above. The temporary SSH setup is for the live session, not the installed system.

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
connects Thunderbird's GPG interface, permits Mattermost to use GNOME Keyring,
and installs the GNOME extensions.
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

| Source         | Applications                                                                          |
| -------------- | ------------------------------------------------------------------------------------- |
| Snap, stable   | Firefox, Thunderbird, Ghostty, Mattermost, Zoom, Okular, LibreOffice                  |
| Flatpak, user  | Nheko work profile, Zathura, NormCap, GPU Screen Recorder                             |
| Nix            | Shared CLI and AI tools, Neovim, zsh, Podman, GPG, desktop helper commands            |
| apt exceptions | Git, Flatpak, uidmap, Copyous libraries, zbar-tools, pinentry-gnome3, python3-gi, imv |

The lists are in `meta/canonical/`. Ghostty's classic confinement is explicit.

The corporate profile uses Ubuntu's coreutils for account lookup through authd.
It does not install Nix coreutils. If a Nix program cannot resolve your user or
group, compare it with the corresponding `/usr/bin` command. Do not change the
account UID or add a duplicate entry to `/etc/passwd`. The test VM uses a local
account and does not test authd lookups.

Tuicr's Rust crates are fetched from the official static archive server with
Cargo.lock checksum verification. `just nix-crate-check` tests a fresh download
without using its cached output. Bootstrap does not need a manual crate prefetch.

`wqr` displays QR codes with `imv`. `wtype` is installed for use with compatible
compositors; it cannot inject keys into GNOME without virtual-keyboard protocol
support.

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

The repo loads `dotfiles-nix-bwrap` and `dotfiles-nix-podman` AppArmor
profiles. Global user-namespace restrictions stay enabled. Test `aibox -p` and
a rootless container. If AppArmor denies another executable, inspect the exact
denial before adding a rule. Do not allow every program under `/nix/store`.

## Mattermost Keyring

The Mattermost Snap lacks the `password-manager-service` plug. `canonical-system`
installs `dotfiles-mattermost-keyring.service` and its path watcher. They add
Secret Service D-Bus access to the Mattermost profile at boot and when snapd
replaces it. The Snap keeps its normal updates and AppArmor enforcement.
This permission gives Mattermost access to the user's unlocked keyring; it
does not restrict access to Mattermost's own entries.

After applying this to a running session, quit Mattermost, including its tray
process, and start it again. Check the result:

```sh
grep 'Secure storage initialized' ~/snap/mattermost-desktop/current/.config/Mattermost/logs/main.log | tail -n 1
```

The result must say `encryption available`. Track the missing plug in the
[Snap package tracker](https://github.com/snapcrafters/mattermost-desktop/issues).
When the package supplies it, connect the plug and remove this local workaround.

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

Mattermost, Thunderbird, and one Nheko `work` profile autostart through
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

## Panel

Vitals supplies CPU usage, maximum sensor temperature, memory usage, and
network receive/send rates. Its monitor action opens `htop` in Ghostty.
Public-IP lookup is disabled. Sensor names and network totals come from Vitals;
select a specific temperature sensor or network device in its preferences if
the defaults are not useful on the laptop.

The repo-owned `corporate-panel@dotfiles` extension adds compact status text:

- `EXT`: connected external display connectors, not a dock identity.
- `APT`: upgrades listed in the local apt cache, excluding Snap and Nix.
- `FAIL`: failed system and user units. A failed query displays `?`, not zero.
- `REBOOT`: `/run/reboot-required` exists. The panel does not reboot the laptop.

The menu opens display settings, `htop`, `pulsemixer`, Thunderbird, failed-unit
details, available apt/Snap updates, and reboot details. Its update action runs
`just update` in the active chezmoi source directory in a terminal. Status checks
run each minute without sudo, package installation, or apt metadata refresh.
The custom labels use the personal panel's green, yellow, and red colours.

GNOME retains the clock, notifications, privacy indicators, and network/audio
controls. Ubuntu AppIndicators supplies the tray. PaperWM retains workspace
navigation. The custom panel does not copy Sway IPC modules, personal VPN
controls, Arch checks, or the webcam process scanner. Module placement and
actions are not identical to Waybar; custom actions are in a menu.

On an existing corporate installation, run outside the sandbox:

```sh
just pkg-apply base
just nix-switch
just apply
just canonical-extensions
just canonical-desktop
```

Log out and log in again to load the new extension. After changes to its
JavaScript, log out and in again to replace GNOME Shell's cached module.
Check both docked and undocked that the panel fits, readings change, menu
actions work, and tray icons appear. Check the lock screen and notifications.
Inspect failures with `journalctl --user -b -g 'Corporate panel'` and
`gnome-extensions info corporate-panel@dotfiles`.

`just canonical-desktop-restore` restores the saved settings, including extension
enablement, unless they were changed afterwards. The extension files remain
installed. The personal and VM roles do not receive them.

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

Use the [disposable desktop VM](canonical-vm.md) to test bootstrap and deployment
before the laptop arrives. It does not replace company provisioning or the
hardware checks below.

`just test` checks package commands, template identities, and role file
boundaries. CI also checks formatting, lint, and Nix profile evaluation. These
checks do not prove that Snap portals, the dock, authd, or GNOME extensions work
on the real laptop. Complete the desktop checks after provisioning before
depending on this machine for meetings.
