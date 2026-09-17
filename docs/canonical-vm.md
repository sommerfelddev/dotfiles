# Canonical Desktop Test VM

This lab uses Ubuntu 26.04.1 Desktop, GNOME/GDM, and the existing `canonical`
role. It does not enroll in Landscape or authd. Do not put the corporate
autoinstall file or company credentials in this lab.

## Host Access

Run outside aibox as your normal user with access to the local LXD socket.
LXD access is equivalent to root access. Do not mount its socket into aibox.
Temporary group access does not require permanent group membership:

```sh
sudo -u "$USER" -g lxd -- "$HOME/.nix-profile/bin/codex" resume \
  --sandbox danger-full-access --ask-for-approval never
```

On Arch, LXD's VM support needs `cdrtools` and its QEMU/OVMF dependencies.
Install missing host packages with pacman before starting. Image and screenshot
tools are in the repo's Nix development shell:

```sh
nix develop ./nix
just canonical-vm-run
```

If the main Ubuntu download server is slow, `canonical-vm-create` accepts an
HTTPS mirror directory as its argument. It resumes a partial ISO download and
still checks the ISO against the signed manifest from `releases.ubuntu.com`.

The lab uses `canonical-lab`, 4 CPUs, 8 GiB RAM, an 80 GiB disk, and the existing
`default` storage pool and `lxdbr0` bridge. It does not change shared profiles,
firewall rules, or other instances. Guests can reach the LAN and VPN through
the existing bridge. No host home directory or credential agent is shared.
Allow several hours for a cold run. The desktop runtimes are large, and the
shared Nix profile can build packages from source.

## Test Credentials

The workflow creates test SSH and disk/login credentials under
`tmp/canonical-vm/secrets/`. The lab directory is private and ignored by both
Git and chezmoi. It also holds the verified ISO, private installer, and reports.
Keep it for retries. Do not publish it or add it to Git.

The VM has encrypted LVM, but its unlock key is in the unencrypted initramfs.
It has passwordless sudo and GDM automatic login. These settings are for this
disposable VM only. They do not provide a secure laptop configuration.
The lab also locks `clock-show-weekday` to false to test policy handling.
The lab keyring service reads the generated login password from a private file
at startup. Bootstrap saves the initial empty keyring before creating the test
keyring. It does not change the corporate role's keyring or PAM configuration.

SSH uses the generated key only, with agent forwarding disabled. Its host key
is read through the trusted local LXD agent and then pinned. A different host
key stops the workflow. The guest creates a dummy GPG signing key.
Its private export stays in the local secrets directory for snapshot retries.

## Operations

`canonical-vm-run` downloads and verifies the Ubuntu ISO, adds the lab installer
data, installs Ubuntu, takes the `clean` snapshot, installs upstream multi-user
Nix, takes `nix-ready`, and runs `canonical-setup` inside the guest. It then
reboots, runs the guest checks, stops the VM, and takes `working`.

The source copy includes current tracked changes and untracked, nonignored
files. It excludes host Git state, lab data, caches, and worktrees. The guest
gets a separate Git repository. No setup recipe runs on the host.

Individual steps are available when a test fails:

```sh
just canonical-vm-status
just canonical-vm-console
just canonical-vm-screenshot
just canonical-vm-logs
just canonical-vm-stop
just canonical-vm-restore nix-ready
just canonical-vm-start
just canonical-vm-sync-source
just canonical-vm-deploy
just canonical-vm-test
```

Restore discards changes in the marked test VM. Snapshots require a stopped VM.
Existing snapshots are not overwritten. Commands reject an instance whose
ownership marker does not match the local lab state.
`canonical-vm-sync-source` discards edits in the guest source checkout. It does
not change the guest's keys or deployed home files. Run it before deployment
when testing a source fix after restoring `nix-ready`.

`canonical-vm-delete` removes only the marked VM and its snapshots. It leaves
the private local lab files for inspection. Remove `tmp/canonical-vm/` yourself
after you no longer need them. Never reuse its credentials on another system.
Remove the cached `installer.iso` before creating another VM when you change
the installer scripts. Keep the original Ubuntu ISO to avoid another download.

## Test Boundary

Guest checks use the real GNOME user session. `canonical-lab-check` requires
Ubuntu, the `canonical` role, a VM, and a root-owned lab marker. It skips company
registration only. The normal `canonical-check` still checks Landscape.

The VM cannot verify company policy, Google/authd login, normal GDM password
login, or laptop hardware. Camera, dock, suspend, and real-account notification
tests still need the laptop. Autologin and the test keyring service do not test
PAM integration. A successful command alone does not prove a visible GUI action.

## Test Results (2026-09-14)

The installed VM boots with encrypted LVM and automatic unlock. The full Nix
profile, Snaps, and Flatpaks installed. All configured GNOME extensions were
active after settings deployment. The policy-lock, GPG signing, rootless Podman,
aibox, and secret-storage checks passed. The stored secret survived a reboot. A screenshot
confirmed the desktop panel and test notification. The source checks and all
unit tests passed.

Keybase Snap 6.5.1 revision 70 corrupted the GNOME settings database when its
GUI started. Its `setup-env.sh` sets `XDG_RUNTIME_DIR` to its `.config`
directory, whose `dconf/user` links to the desktop database. A controlled
launch changed the header from `GVariant` to `G\0ariant`. On later boots,
dconf discarded the database and the desktop extensions disappeared.
Keybase is removed from the VM and excluded from the corporate laptop profile.
After removal, the deployment and final reboot checks passed. All configured
extensions stayed active without reapplying settings, and the stored test
secret survived. The final screenshot confirmed that the panel remained visible.

These limits remain:

- Mattermost remains a Snap. Revision 850 lacks the keyring plug. The local
  Mattermost-only AppArmor rule permits Secret Service access, and the app
  reports `encryption available`. AppArmor remains enforced. The path watcher
  restored the rule after a simulated profile replacement. Both subsequent
  reboot checks passed with encryption available. Real-account login was not
  tested. See [Mattermost keyring](canonical-laptop.md#mattermost-keyring).
- Flatpak reported end-of-life KDE runtimes for Nheko (6.8) and NormCap (6.9).
  The installed stable releases still use these runtimes.

The crates.io HTTP 403 failure is fixed in the Nix package definition. Tuicr's
crate downloads use `static.crates.io` and retain the Cargo.lock checksums.
All 377 crate downloads were forced in the Ubuntu VM, without reusing their
cached outputs, and passed hash verification. The Nix profile build also passed.
No manual crate prefetch is needed. Run `just nix-crate-check` to repeat a
forced download of one locked crate. The full download test log is
`tmp/canonical-vm/reports/tuicr-forced-downloads.log`.

The full guest `just update` passed after GitHub's API rate limit cleared.
This included the package updates, release check, Nix flake update and
activation, Neovim update, and GNOME extension update. No new APT packages
were installed. The download checks above cover the crate-cache failure; they
do not repeat the OS installation or company provisioning.
Use login Zsh for CLI tests, as Ghostty does; Bash does not load the Home
Manager session variables used by the parser compiler.

The stopped `working` snapshot restored the guest disk state: a test file added
after the snapshot was absent after restore. An early reboot test caused a
GNOME shutdown timeout and activated its extension failure protection. Desktop
readiness now waits for GNOME's extension startup check to finish. It does not
disable that protection. The final reboot check also verifies extensions
without applying settings again. The `working` snapshot was replaced after the
update and reboot tests. It excludes Keybase and includes the Mattermost
keyring workaround and the crate download fix. The VM is stopped. Logs and screenshots are under
`tmp/canonical-vm/reports/`.

References: [Ubuntu images](https://releases.ubuntu.com/26.04/),
[autoinstall](https://canonical-subiquity.readthedocs-hosted.com/en/latest/reference/autoinstall-reference.html),
and [LXD VMs](https://canonical.com/lxd/docs/latest/howto/instances_create/).
