{ config, pkgs, lib, dotfilesRoot, ... }:

# Shared Home-Manager module: ONLY package installation. Config-file
# deployment is *not* handled here — on the Arch host, chezmoi owns
# every dotfile under $HOME; on the remote-dev VM, `vm.nix` carries
# its own `xdg.configFile`/`home.activation` block since chezmoi isn't
# installed there. Keeping this module deployment-agnostic prevents
# home-manager from conflicting with chezmoi on the host (which would
# otherwise materialize as `.backup` files on every `nix-switch`).
#
# Policy: this profile carries leaf CLI tools, editor/AI-agent runtimes
# (node, uv), and build *orchestrators* (cmake, ninja, ccache, sccache).
# It must NEVER carry actual compilers or linkers — those would shadow
# the system's and silently link projects against nixpkgs glibc/libstdc++
# instead of the system sysroot.
#
# Forbidden on PATH from this module: cc, c++, gcc, g++, clang, clang++,
# ld, ld.lld, ar, nm, objcopy, make, meson, pkg-config, autoconf,
# automake, libtool, python, python3, pip, cargo, rustc, go.
#
# Allowed: orchestrators that delegate to whatever compiler is in PATH
# (cmake, ninja, ccache, sccache), instrumentation/analysis that hooks
# at the syscall/library boundary (valgrind, gdb, lldb, strace), and
# source-only tooling (doxygen, clang-tools — clangd/clang-format/
# clang-tidy, no compiler driver). Project-specific compilers/linkers
# go in project-local flake.nix + direnv `.envrc`, NOT here.
#
# Editor/AI runtimes: node, npm, npx (via `nodejs`), uv, uvx (via `uv`
# — manages its own python interpreters under XDG, doesn't install a
# system python3).

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
    git-absorb
    difftastic

    # JSON / YAML
    jq
    yq-go

    # System
    htop
    fastfetch
    hyperfine
    duf
    gdu
    procs
    yazi

    # Net
    curl
    curlie
    wget
    dog
    nmap
    rsync
    openssh

    # Debug / trace / profile — moved off pacman. User policy: only
    # used against own builds, so glibc/kernel version skew vs the
    # system isn't an issue. Only `perf` stays system (it links against
    # the running kernel ABI; pacman's matches the kernel package).
    gdb
    lldb        # also brings lldb-dap (used by dap.lua via type="lldb")
    strace
    samply
    t-rec
    valgrind

    # Build orchestrators — these only delegate to whatever compiler is
    # in PATH; they don't ship cc/c++/ld themselves, so no shadowing.
    cmake
    ninja
    ccache
    sccache

    # Source-only docs/analysis (no compiler driver)
    doxygen

    # Docs
    tldr
    man-db
    man-pages
    pandoc

    # Secrets — `pass-otp` is wired as an extension so `pass otp ...`
    # works against the same store. `pass` from pacman is removed.
    gnupg
    (pass.withExtensions (exts: [ exts.pass-otp ]))

    # C/C++ source tooling (no compiler driver in PATH)
    clang-tools

    # CI runner (drives podman from pacman; act itself is just a Go binary)
    act

    # Editor/AI agent runtimes — NOT for project builds (see policy above)
    nodejs_24 # copilot-language-server requires Node 24 (see ai.lua)
    uv        # for project tooling that asks for `uv`/`uvx`; brings no python

    # AI coding agents
    claude-code
    codex # OpenAI Codex CLI (rust rewrite); replaces pacman openai-codex-bin
    github-copilot-cli # `copilot`; prebuilt-binary derivation since 1.0.43

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
    dockerfile-language-server
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
    prettier
    shfmt
    stylua

    # Linters
    codespell
    hadolint
    markdownlint-cli
    selene
    shellcheck
    shellharden
    stylelint
    typos
    yamllint

    # DAPs / debuggers — `lldb-dap` ships in pkgs.lldb (declared in the
    # debug/trace block above). dap configs in plugins/debug.lua target
    # it via `type = "lldb"`.

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

  # ── XDG base dirs ──────────────────────────────────────────────────────────
  xdg.enable = true;

  # ── Enable HM-managed activation messages ──────────────────────────────────
  programs.home-manager.enable = true;
}
