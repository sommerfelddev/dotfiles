{
  config,
  pkgs,
  lib,
  dotfilesRoot,
  ...
}:

# Arch host Home-Manager package profile.

let
  whisper-cpp-model-base = import ./whisper-model.nix { inherit pkgs lib; };
  pass-secret-service-rust = pkgs.rustPlatform.buildRustPackage rec {
    pname = "pass-secret-service";
    version = "0.7.0";

    src = pkgs.fetchFromGitHub {
      owner = "grimsteel";
      repo = "pass-secret-service";
      rev = "v${version}";
      hash = "sha256-cBDGxF1ETyszwHZJwN8n+lwKcpOU8Xt1XTOGbUHj9UI=";
    };

    cargoHash = "sha256-Ko8LlgPG6kl+pZ47jrFnKdc+9i7/eh9DMRtG2SWQGjQ=";
    nativeBuildInputs = [ pkgs.makeWrapper ];

    postInstall = ''
      wrapProgram "$out/bin/pass-secret-service" \
        --prefix PATH : "${lib.makeBinPath [ pkgs.gnupg ]}"
    '';

    meta = {
      description = "Implementation of org.freedesktop.secrets using pass";
      homepage = "https://github.com/grimsteel/pass-secret-service";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.linux;
      mainProgram = "pass-secret-service";
    };
  };
  arkenfox-userjs-profile =
    pkgs.runCommand "arkenfox-userjs-profile-${pkgs.arkenfox-userjs.version}" { }
      ''
        install -Dm644 ${pkgs.arkenfox-userjs}/user.js $out/share/arkenfox-userjs/user.js
        install -Dm644 ${pkgs.arkenfox-userjs}/user.cfg $out/share/arkenfox-userjs/user.cfg
      '';
in
{
  imports = [ ./common.nix ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # Used by nvim-treesitter parser builds without adding a compiler to PATH.
  home.sessionVariables.NVIM_TREESITTER_CC = "${pkgs.stdenv.cc}/bin/cc";

  home.packages = with pkgs; [
    uutils-coreutils-noprefix

    # ── Thunderbird helpers ───────────────────────────────────────────────────
    external-editor-revived

    # ── Mail: ProtonMail Bridge ───────────────────────────────────────────────
    protonmail-bridge

    # ── Keybase ──────────────────────────────────────────────────────────────
    keybase-gui

    # ── Secrets portal ────────────────────────────────────────────────────────
    pass-secret-service-rust

    # ── Wayland session: bars, launchers, notifiers, daemons ──────────────────
    waybar
    mako
    fuzzel
    wofi # used by bemoji + mako-history.sh
    swayidle
    swayr # auto-tiling + window switcher
    inhibridge # browser idle-inhibit bridge → systemd-inhibit
    bemoji # emoji picker (wofi backend)
    wob # volume/brightness OSD
    poweralertd

    # ── Wayland: capture + clipboard + image viewing ─────────────────────────
    grim
    slurp
    wf-recorder
    wtype
    wl-clipboard # wl-copy + wl-paste
    cliphist # clipboard history (used by cliphist-{text,image} units)

    # ── Media control ────────────────────────────────────────────────────────
    playerctl # MPRIS over session bus
    pulsemixer # TUI for PipeWire/PulseAudio

    # ── General CLIs ─────────────────────────────────────────────────────────
    qrencode
    torsocks
    lshw
    yt-dlp
    streamlink
    xdg-utils # xdg-open, used by yazi/linkhandler/OPENER

    # ── File sync ───────────────────────────────────────────────────────────────
    syncthing

    # ── Bitcoin wallet ───────────────────────────────────────────────────────
    sparrow

    # ── Browser hardening ────────────────────────────────────────────────────
    arkenfox-userjs-profile

    # ── OCR ──────────────────────────────────────────────────────────────────
    (tesseract.override {
      enableLanguages = [
        "eng"
        "por"
      ];
    })

    # ── Speech-to-text (dictate script) ──────────────────────────────────────
    (whisper-cpp.override { vulkanSupport = true; })
    whisper-cpp-model-base
  ];

  # ── Smartcard (Yubikey) ────────────────────────────────────────────────────
  home.file.".gnupg/scdaemon.conf".text = ''
    disable-ccid
    pcsc-driver /usr/lib/libpcsclite.so.1
  '';

  # ── Keybase ────────────────────────────────────────────────────────────────
  services.keybase.enable = true;
  services.kbfs.enable = true;

  # Home Manager assumes the NixOS FUSE wrapper. Arch provides fusermount
  # through fuse2 in /usr/bin.
  systemd.user.services.kbfs.Service = {
    Environment = lib.mkForce [
      "PATH=/usr/bin:${
        lib.makeBinPath [
          pkgs.keybase
          pkgs.kbfs
        ]
      }"
      "KEYBASE_SYSTEMD=1"
    ];
    ExecStartPre = lib.mkForce "${pkgs.coreutils}/bin/mkdir -p %t/keybase/kbfs";
    ExecStart = lib.mkForce "${lib.getExe' pkgs.kbfs "kbfsfuse"} %t/keybase/kbfs";
    ExecStopPost = lib.mkForce "/usr/bin/fusermount -u %t/keybase/kbfs";
  };

  systemd.user.services.keybase-gui = {
    Unit = {
      Description = "Keybase GUI";
      Requires = [
        "keybase.service"
        "kbfs.service"
      ];
      After = [
        "graphical-session.target"
        "keybase.service"
        "kbfs.service"
      ];
      PartOf = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Environment = [
        "KEYBASE_AUTOSTART=1"
        "NIXOS_OZONE_WL=1"
        "PATH=${
          lib.makeBinPath [
            pkgs.keybase
            pkgs.gnugrep
            pkgs.xdg-utils
          ]
        }:/usr/bin"
      ];
      ExecStart = lib.getExe pkgs.keybase-gui;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "sway-session.target" ];
  };
}
