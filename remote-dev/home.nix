{ config, pkgs, lib, dotfilesRoot, ... }:

let
  # The dotfiles checkout is cloned to ~/.local/share/dotfiles by bootstrap.sh.
  # We do NOT use `dotfilesRoot` as a Nix store path because that would copy
  # the entire repo into the store on every rebuild. Instead, we symlink
  # config dirs at runtime via `config.lib.file.mkOutOfStoreSymlink`, which
  # points at the live working tree so edits take effect without a rebuild.
  dotfiles = "${config.home.homeDirectory}/.local/share/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "25.05";

  # ── Packages ────────────────────────────────────────────────────────────────
  # Mirrors the dev-tool subset of `meta/base.txt` on the Arch host. Tools that
  # only make sense on a workstation (procs/gdu/duf for sysadmin, lazygit
  # unused, node/yarn only needed for markdown-preview on GUI) are excluded.
  home.packages = with pkgs; [
    # Editor + multiplexer
    neovim
    zellij
    tree-sitter

    # Search / move
    ripgrep
    fd
    fzf
    sd
    choose

    # Viewers
    bat
    lsd
    glow

    # Git stack
    git
    gh
    delta

    # JSON / YAML
    jq
    yq-go

    # System
    htop
    fastfetch

    # Net
    curl
    curlie
    wget
    dog
    rsync
    openssh

    # Docs
    tldr
    man-db
    man-pages

    # Secrets (user can bring their key separately)
    gnupg
    pass

    # Zsh and plugins (sourced from $HOME/.nix-profile/share/... by the shared zshrc)
    zsh
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-history-substring-search
  ];

  # ── direnv + nix-direnv ─────────────────────────────────────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = false; # zshrc already calls `eval "$(direnv hook zsh)"`
  };

  # ── Shared config symlinks ──────────────────────────────────────────────────
  # Live symlinks back into the cloned working tree so `git pull` is enough
  # to update configs — no `home-manager switch` required after every edit.
  xdg.configFile = {
    "nvim".source             = link "dot_config/nvim";
    "zellij".source           = link "dot_config/zellij";
    "zsh/.zshrc".source       = link "dot_config/zsh/dot_zshrc";
    "zsh/.zprofile".source    = link "dot_config/zsh/dot_zprofile";
    "ghostty".source          = link "dot_config/ghostty";   # for terminfo refs only
    "direnv/direnvrc".source  = link "dot_config/direnv/direnvrc";
  };

  # ZDOTDIR redirect so login shells find ~/.config/zsh/.zprofile etc.
  home.file.".zshenv".text = ''
    export ZDOTDIR="$HOME/.config/zsh"
    [[ -r "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
  '';

  # ── XDG base dirs (Ubuntu doesn't set these in /etc/profile.d by default) ──
  xdg.enable = true;

  # ── Enable HM-managed activation messages ──────────────────────────────────
  programs.home-manager.enable = true;
}
