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
  # Policy: this profile carries leaf CLI tools plus editor/AI-agent
  # runtimes (node, uv). It must NEVER carry anything the project build
  # might invoke. Forbidden on PATH (would shadow Ubuntu's and break
  # builds against the system sysroot/libc): cc, c++, gcc, g++, clang,
  # clang++, ld, ld.lld, ar, nm, objcopy, make, cmake, ninja, meson,
  # pkg-config, autoconf, automake, libtool, python, python3, pip,
  # cargo, rustc, go. If a project needs a newer toolchain, put it in
  # a project-local flake.nix + direnv `.envrc`, NOT here.
  #
  # Allowed runtimes (used only by Mason/editor/AI agents): node, npm,
  # npx (via `nodejs`), uv, uvx (via `uv` — does NOT install a python3,
  # manages its own interpreters under XDG). clang-tools is allowed
  # because it ships only formatters/linters/clangd, no compiler driver.
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
    zoxide
    just

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

    # C/C++ source tooling (no compiler driver in PATH)
    clang-tools

    # Editor/AI agent runtimes — NOT for project builds (see policy above)
    nodejs_24 # Mason npm LSPs + copilot-language-server (needs Node 24, see ai.lua)
    uv        # Mason python LSPs in isolated venvs; brings `uv`/`uvx` only
    jre       # for Mason's groovy-language-server (headless Java runtime)

    # Mason's pip-installer probes `python3.13`, `python3.12`, ..., `python3.10`
    # in PATH (in addition to `python3`) when picking an interpreter for the
    # per-pkg venvs it creates. Ubuntu 20.04 ships only `python3` = 3.8 which
    # is too old for codespell/mdformat/yamllint/etc. We expose ONLY the
    # versioned `python3.11` binary so we don't shadow the system `python3`
    # (preserving the leaf-tools policy: system builds keep using /usr/bin/python3).
    (pkgs.runCommand "python311-versioned-only" { } ''
      mkdir -p $out/bin
      ln -s ${pkgs.python311}/bin/python3.11 $out/bin/python3.11
    '')

    # Rust toolchain for Mason packages whose only install source is
    # `cargo install` (shellharden). The host has these via the Arch
    # package manager; on the VM Mason needs cargo+rustc on PATH or it
    # bails with ENOENT.
    cargo
    rustc

    # AI coding agents
    claude-code
    github-copilot-cli # NB: pkgs.copilot-cli is AWS Copilot, NOT this

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
    "git/config".source       = link "dot_config/git/config";
    "git/attributes".source   = link "dot_config/git/attributes";
    "git/ignore".source       = link "dot_config/git/ignore";
  };

  # ~/.ssh/config from the dotfiles tree (read-only); keys + known_hosts
  # stay machine-local on the VM.
  home.file.".ssh/config".source = link "private_dot_ssh/config";

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
