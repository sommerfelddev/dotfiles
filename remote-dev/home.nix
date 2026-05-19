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

  home.sessionVariables = {
    # Ubuntu 20.04 still defaults to cgroups v1; podman 5 warns on every
    # invocation. Flipping to v2 is a host-level reboot (see README) and
    # only matters if we need --memory/--cpus, so silence the warning.
    PODMAN_IGNORE_CGROUPSV1_WARNING = "1";
  };

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
    mergiraf

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
    basedpyright # see lsp.lua: Mason's pypi distro can't install on Ubuntu 20.04
                 # (nodejs-wheel-binaries has only manylinux_2_28 wheels which
                 # uv's python rejects since it's manylinux2014; source build
                 # of Node 24 needs gcc >=10 and host gcc is 9.4)

    # NB: python3.11 for Mason is NOT installed here — see bootstrap.sh
    # step 4. Nix's python disables manylinux wheel support by design
    # (its libc is patched and doesn't satisfy any manylinux policy), so
    # pip in a nix-python venv falls back to source builds for packages
    # like `nodejs-wheel-binaries` (pulled in by basedpyright). That
    # source build then fails on Ubuntu 20.04's gcc 9.4 (no C++20).
    # Bootstrap uses `uv python install 3.11` to fetch a portable
    # manylinux-aware CPython and symlinks it to ~/.local/bin/python3.11.

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

    # Rootless podman (see README "Podman" section for host prerequisites).
    # The nix `podman` is wrapped to find these helpers via /nix/store paths,
    # so we don't need to write a containers.conf for `helper_binaries_dir`.
    podman
    crun         # OCI runtime (lighter than runc; default for rootless)
    conmon       # container monitor process
    netavark     # default network stack on podman 4+
    aardvark-dns # DNS for netavark networks
    slirp4netns  # rootless user-mode networking
    passt        # pasta backend (slirp4netns successor; podman picks it up)
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

  # ── Rootless podman config ──────────────────────────────────────────────────
  # Kept inline (not in the chezmoi tree) because Arch's system-wide
  # /etc/containers defaults already work there; these files exist only
  # to give nix's user-installed podman sane rootless defaults.
  xdg.configFile."containers/registries.conf".text = ''
    unqualified-search-registries = ["docker.io", "quay.io", "ghcr.io"]
    short-name-mode = "permissive"
  '';

  xdg.configFile."containers/storage.conf".text = ''
    [storage]
    # runroot/graphroot default to $XDG_RUNTIME_DIR/containers and
    # $XDG_DATA_HOME/containers/storage respectively for rootless — leave unset.
    driver = "overlay"

    [storage.options.overlay]
    # Kernel >=5.13 supports rootless overlay natively (VM is on 5.15),
    # so mount_program is left unset → uses the kernel driver directly
    # instead of fuse-overlayfs.
  '';

  xdg.configFile."containers/policy.json".text = builtins.toJSON {
    default = [ { type = "insecureAcceptAnything"; } ];
    transports.docker-daemon."" = [ { type = "insecureAcceptAnything"; } ];
  };

  # ~/.ssh/config from the dotfiles tree (read-only); keys + known_hosts
  # stay machine-local on the VM. We can't symlink via home.file because
  # mkOutOfStoreSymlink exposes the working-tree perms (0664 under Ubuntu's
  # default umask 002) and OpenSSH refuses any group-writable ssh_config.
  # Materialize a real 0600 file via activation instead.
  home.activation.sshConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run install -D -m 600 \
      "${dotfiles}/private_dot_ssh/config" "$HOME/.ssh/config"
  '';

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
