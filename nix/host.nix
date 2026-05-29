{ config, pkgs, lib, dotfilesRoot, ... }:

# Arch host Home-Manager profile. Layered on top of `common.nix`; adds
# only host-specific concerns that don't make sense on the VM.
#
# Dotfile deployment on the host is owned entirely by **chezmoi** (run
# via `just apply` / `just sync`). Home-Manager here only installs
# binaries and writes the host-only smartcard config below.

{
  imports = [ ./common.nix ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # ── Thunderbird helpers (host only) ────────────────────────────────────────
  # external-editor-revived is the native-messaging host that lets the
  # Thunderbird addon hand a composing draft to $EDITOR. We run TB as the
  # org.mozilla.thunderbird flatpak; the AUR package would drag in system
  # `thunderbird` as a hard dep, so we take it from nixpkgs here instead
  # (the nix derivation has no mailer dep). The bridge wiring lives in
  # run_onchange_after_deploy-tb-eer.sh.tmpl; it auto-detects the binary
  # under ~/.nix-profile and the manifest gets relocated into the TB
  # flatpak sandbox.
  home.packages = with pkgs; [
    external-editor-revived
  ];

  # ── Smartcard (Yubikey) ────────────────────────────────────────────────────
  # Nix's gnupg ships its own scdaemon. Delegate to the system pcscd
  # service instead of letting nix's scdaemon open the USB device
  # directly (which would race with pcscd). `pcsclite` provides the
  # shared library at the path below and stays in `meta/base.txt`.
  home.file.".gnupg/scdaemon.conf".text = ''
    disable-ccid
    pcsc-driver /usr/lib/libpcsclite.so.1
  '';
}
