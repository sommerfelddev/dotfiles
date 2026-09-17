{ pkgs, lib, ... }:
{
  imports = [ ./common.nix ];
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.sessionVariables.NVIM_TREESITTER_CC = "${pkgs.stdenv.cc}/bin/cc";
  home.packages = with pkgs; [
    external-editor-revived
    gnome-extensions-cli
    wl-clipboard
    wtype
    qrencode
    libnotify
    playerctl
    pulseaudio
    pulsemixer
    (tesseract.override {
      enableLanguages = [
        "eng"
        "por"
      ];
    })
    whisper-cpp
    (import ./whisper-model.nix { inherit pkgs lib; })
  ];
}
