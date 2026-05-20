{ config, pkgs, lib, dotfilesRoot, ... }:

# Arch host Home-Manager profile. Layered on top of `common.nix`; adds
# only host-specific concerns that don't make sense on the VM.

{
  imports = [ ./common.nix ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

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
