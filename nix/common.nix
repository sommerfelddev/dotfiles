{ config, pkgs, lib, dotfilesRoot, ... }:

# Shared Home-Manager module: the leaf-CLI subset, editor/AI-agent
# runtimes, and the shared dotfiles symlinks used by **both** the Arch
# host and the Ubuntu remote-dev VM. Profile-specific extras live in
# `host.nix` and `vm.nix`.
#
# Policy: this profile carries leaf CLI tools plus editor/AI-agent
# runtimes (node, uv). It must NEVER carry anything the project build
# might invoke. Forbidden on PATH (would shadow the system's and break
# builds against the system sysroot/libc): cc, c++, gcc, g++, clang,
# clang++, ld, ld.lld, ar, nm, objcopy, make, cmake, ninja, meson,
# pkg-config, autoconf, automake, libtool, python, python3, pip,
# cargo, rustc, go. If a project needs a newer toolchain, put it in a
# project-local flake.nix + direnv `.envrc`, NOT here.
#
# Allowed runtimes (used only by editor/AI agents): node, npm, npx
# (via `nodejs`), uv, uvx (via `uv` — does NOT install a python3,
# manages its own interpreters under XDG). `clang-tools` is allowed
# because it ships only formatters/linters/clangd, no compiler driver.

let
  dotfiles = "${config.home.homeDirectory}/.local/share/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  home.stateVersion = "25.05";

  # ── Packages ────────────────────────────────────────────────────────────────
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
    mergiraf

    # JSON / YAML
    jq
    yq-go

    # System
    htop
    fastfetch
    hyperfine

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

    # Secrets — `pass-otp` is wired as an extension so `pass otp ...`
    # works against the same store. `pass` from pacman is removed.
    gnupg
    (pass.withExtensions (exts: [ exts.pass-otp ]))

    # C/C++ source tooling (no compiler driver in PATH)
    clang-tools

    # Editor/AI agent runtimes — NOT for project builds (see policy above)
    nodejs_24 # copilot-language-server requires Node 24 (see ai.lua)
    uv        # for project tooling that asks for `uv`/`uvx`; brings no python

    # AI coding agents
    claude-code
    github-copilot-cli # NB: pkgs.copilot-cli is AWS Copilot, NOT this

    # ── LSPs / formatters / linters / DAPs ─────────────────────────────────
    # Replaces Mason entirely (phase p6 of the nix migration rips out
    # mason-tool-installer). The set tracks the previous
    # `ensure_installed` list in dot_config/nvim/lua/plugins/lsp.lua, with
    # five niche tools dropped: groovy-language-server (Mason-only build,
    # upstream stale), npm-groovy-lint, nginx-language-server,
    # nginx-config-formatter, systemdlint (all rarely-edited domains;
    # losing them is acceptable).

    # LSPs
    actionlint
    autotools-language-server
    basedpyright
    bash-language-server
    dockerfile-language-server-nodejs
    gh-actions-language-server
    just-lsp
    lua-language-server
    neocmakelsp
    ruff
    rust-analyzer
    systemd-language-server
    taplo
    typescript-language-server
    vscode-langservers-extracted   # cssls + html + jsonls + eslint
    yaml-language-server

    # Formatters
    mdformat
    nodePackages.prettier
    shfmt
    stylua

    # Linters
    codespell
    hadolint
    nodePackages.jsonlint
    markdownlint-cli
    selene
    shellcheck
    shellharden
    stylelint
    typos
    yamllint

    # DAPs / debuggers — `lldb-dap` (from pkgs.lldb) is the upstream
    # successor to vscode-lldb's `codelldb`. dap configs in
    # plugins/debug.lua target it via `type = "lldb"`.
    lldb

    # Zsh and plugins (loaded from $HOME/.nix-profile/share/... by the
    # shared zshrc; nix-profile path is preferred, system path is the
    # fallback for un-bootstrapped states).
    zsh
    zsh-completions
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
    # Git hooks: source filenames carry the chezmoi `executable_` attribute
    # prefix which only chezmoi strips. In nix-managed setups we use raw
    # symlinks, so map each hook to its stripped name explicitly. The
    # executable bit comes from the working-tree file mode (git resolves
    # the symlink).
    "git/hooks/pre-push".source = link "dot_config/git/hooks/executable_pre-push";
    "git/hooks/pre-commit".source = link "dot_config/git/hooks/executable_pre-commit";
    "git/hooks/commit-msg".source = link "dot_config/git/hooks/executable_commit-msg";
    "git/hooks/post-commit".source = link "dot_config/git/hooks/executable_post-commit";
    "git/hooks/_dispatch.sh".source = link "dot_config/git/hooks/_dispatch.sh";
  };

  # ~/.ssh/config from the dotfiles tree (read-only); keys + known_hosts
  # stay machine-local. We can't symlink via home.file because
  # mkOutOfStoreSymlink exposes the working-tree perms (0664 under a
  # default umask 002) and OpenSSH refuses any group-writable ssh_config.
  # Materialize a real 0600 file via activation instead.
  home.activation.sshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run install -D -m 600 \
      "${dotfiles}/private_dot_ssh/config" "$HOME/.ssh/config"
  '';

  # ZDOTDIR redirect so login shells find ~/.config/zsh/.zprofile etc.
  # Also source HM's session-vars — HM normally drops these into
  # ~/.profile, but zsh login shells don't read .profile, and we don't
  # use programs.zsh.enable.
  home.file.".zshenv".text = ''
    if [ -r "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
      . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
    fi
    export ZDOTDIR="$HOME/.config/zsh"
    [[ -r "$ZDOTDIR/.zshenv" ]] && source "$ZDOTDIR/.zshenv"
  '';

  # ── XDG base dirs ──────────────────────────────────────────────────────────
  xdg.enable = true;

  # ── Enable HM-managed activation messages ──────────────────────────────────
  programs.home-manager.enable = true;
}
