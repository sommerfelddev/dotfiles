{ config, pkgs, lib, dotfilesRoot, ... }:

# Arch host Home-Manager profile. Layered on top of `common.nix`; adds
# only host-specific concerns that don't make sense on the VM (wayland
# session tools, Yubikey, host-only CLIs / GUIs).
#
# Dotfile deployment on the host is owned entirely by **chezmoi** (run
# via `just apply` / `just sync`). Home-Manager here only installs
# binaries and writes the host-only smartcard config below.
#
# Migration policy: a tool lives here iff nixpkgs ships a working
# equivalent AND it has no tight system coupling (no setuid, no
# /usr/lib/systemd/system unit, no udev rule, no system D-Bus
# activation, no /usr/share/wayland-sessions entry, no shared lib that
# other pacman pkgs link, no system fontconfig path, no PAM, no Qt
# plugin search path, no kernel/firmware/initramfs touchpoint).
# User-scope systemd units are NOT system coupling — nix drops them in
# ~/.nix-profile/share/systemd/user/ and systemd picks them up.

let
  # Whisper.cpp base model — packaged inline because nixpkgs doesn't
  # ship the .bin blobs. Sourced from the upstream huggingface mirror
  # (same URL the AUR `whisper.cpp-model-base` uses). The dictate script
  # at dot_local/bin/executable_dictate defaults to
  # ~/.nix-profile/share/whisper-cpp-models/ggml-base.bin.
  whisper-cpp-model-base = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "whisper-cpp-model-base";
    version = "1.0";
    src = pkgs.fetchurl {
      url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin";
      hash = "sha256-YO1bw90U7qhWST0zQ0m0BXgt3K8AKNS130CINF+6Lv4=";
    };
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      install -Dm644 $src $out/share/whisper-cpp-models/ggml-base.bin
      runHook postInstall
    '';
    meta = with lib; {
      description = "Whisper.cpp ggml-base.bin model (142 MB, multilingual)";
      homepage = "https://huggingface.co/ggerganov/whisper.cpp";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
in
{
  imports = [ ./common.nix ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.packages = with pkgs; [
    # ── Thunderbird helpers ───────────────────────────────────────────────────
    # external-editor-revived is the native-messaging host that lets the
    # Thunderbird addon hand a composing draft to $EDITOR. We run TB as the
    # org.mozilla.thunderbird flatpak; the AUR package would drag in system
    # `thunderbird` as a hard dep, so we take it from nixpkgs here instead
    # (the nix derivation has no mailer dep). The bridge wiring lives in
    # run_onchange_after_deploy-tb-eer.sh.tmpl; it auto-detects the binary
    # under ~/.nix-profile and the manifest gets relocated into the TB
    # flatpak sandbox.
    external-editor-revived

    # ── Mail: ProtonMail Bridge ───────────────────────────────────────────────
    # Headless IMAP/SMTP gateway (127.0.0.1:1143/1025) consumed by the
    # Thunderbird flatpak and `git send-email`. No system coupling: it's a
    # pure user daemon with a repo-owned user unit at
    # dot_config/systemd/user/protonmail-bridge.service (run --noninteractive,
    # pass-backed vault via PASSWORD_STORE_DIR). Replaces the AUR
    # `protonmail-bridge-core`.
    protonmail-bridge

    # ── Wayland session: bars, launchers, notifiers, daemons ──────────────────
    # Pure user-session GUIs/daemons — no system unit, no D-Bus activation
    # file under /usr/share/dbus-1, no login-manager session entry. The
    # corresponding user-scope systemd units live under
    # dot_config/systemd/user/ and reference these binaries by an absolute
    # %h/.nix-profile/bin/<name> path. (Bare names do NOT work: systemd's
    # ExecStart binary resolution does not use the imported/environment.d
    # PATH of the --user manager, so a bare name fails with 203/EXEC even
    # though `systemctl --user show-environment` shows the nix profile on
    # PATH. The %h specifier expands to $HOME at unit-load time.)
    waybar
    mako
    fuzzel
    wofi          # used by bemoji + mako-history.sh
    swayidle
    swayr         # auto-tiling + window switcher
    inhibridge    # browser idle-inhibit bridge → systemd-inhibit
    bemoji        # emoji picker (wofi backend)
    wob           # volume/brightness OSD
    poweralertd

    # ── Wayland: capture + clipboard + image viewing ─────────────────────────
    grim
    slurp
    wf-recorder
    wtype
    wl-clipboard  # wl-copy + wl-paste
    cliphist      # clipboard history (used by cliphist-{text,image} units)

    # ── Media control ────────────────────────────────────────────────────────
    playerctl     # MPRIS over session bus
    pulsemixer    # TUI for PipeWire/PulseAudio

    # NOTE: GPU/OpenGL & EGL apps (ghostty, imv, wl-mirror) are
    # intentionally NOT here — they stay on pacman/AUR. Nix-built GL apps on
    # a non-NixOS host can't locate the system Mesa/DRI driver (the FHS
    # /usr/lib drivers don't match nix's search paths) and fail at startup
    # with "missing OpenGL context". On pacman they link against system Mesa.
    # ghostty/imv/wl-mirror live in meta/base.txt. Sparrow is JavaFX-based and
    # runs correctly from nix on the host.

    # ── General CLIs migrated off pacman ──────────────────────────────────────
    qrencode
    torsocks
    lshw
    yt-dlp
    streamlink
    xdg-utils     # xdg-open, used by yazi/linkhandler/OPENER

    # ── File sync ───────────────────────────────────────────────────────────────
    # Package-only migration from pacman. The boot-time system service is the
    # repo-owned syncthing@sommerfeld.service tracked in systemd-units/system.txt
    # and backed by etc/systemd/system/syncthing@.service.
    syncthing

    # ── Work VPN ──────────────────────────────────────────────────────────────
    # Check Point VPN client. The command-mode system service is repo-owned at
    # etc/systemd/system/snx-rs.service and exposes the daemon that snxctl uses.
    snx-rs

    # ── Bitcoin wallet ───────────────────────────────────────────────────────
    # Replaces the former AUR wallet package after host GUI + BitBox smoke
    # testing.
    sparrow

    # chezmoi & paru — both are pure user CLIs. `paru` wraps pacman+makepkg
    # but doesn't link them; it just shells out. bootstrap.sh installs a
    # one-shot pacman `chezmoi` for the very first `chezmoi init --apply`,
    # then `paru -Rns chezmoi paru` after the first nix-switch drops the
    # pacman copies (the nix-profile copies on PATH take over).
    chezmoi
    paru

    # ── OCR ──────────────────────────────────────────────────────────────────
    # Override merges eng + por language data into a single derivation,
    # replacing three pacman packages (tesseract, tesseract-data-eng,
    # tesseract-data-por).
    (tesseract.override { enableLanguages = [ "eng" "por" ]; })

    # ── Speech-to-text (dictate script) ──────────────────────────────────────
    # whisper.cpp with Vulkan acceleration. `mainProgram = "whisper-cli"`
    # matches the binary the dictate script invokes. The base model below
    # is a separate derivation so we can drop the AUR `whisper.cpp-model-base`.
    (whisper-cpp.override { vulkanSupport = true; })
    whisper-cpp-model-base
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
