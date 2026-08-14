{
  config,
  pkgs,
  lib,
  dotfilesRoot,
  ...
}:

# Shared Home-Manager package profile. Chezmoi owns dotfile deployment.

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
    chezmoi

    # Viewers
    bat
    lsd
    glow

    # Git stack
    (git.override { sendEmailSupport = true; })
    gh
    delta
    mergiraf
    git-absorb
    difftastic

    # JSON / YAML
    jq
    yq-go

    # System
    dash
    # Prefer Rust uutils for the unprefixed replacements that pass repo-local
    # usage checks. Keep GNU tar on the system PATH for now; uutils-tar still
    # rejects common GNU tar invocations like `tar -czf`.
    uutils-coreutils-noprefix
    uutils-diffutils
    uutils-findutils
    uutils-procps
    uutils-sed
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
    bind.dnsutils
    nmap
    rsync
    openssh
    mosh

    # Debug / trace / profile
    gdb
    lldb # also brings lldb-dap (used by dap.lua via type="lldb")
    strace
    samply
    t-rec
    valgrind

    # Build orchestrators
    cmake
    ninja
    ccache
    sccache

    # Source-only docs/analysis (no compiler driver)
    doxygen

    # Docs
    less
    tldr
    man-db
    man-pages
    pandoc

    # Secrets — `pass-otp` is wired as an extension so `pass otp ...`
    # works against the same store.
    gnupg
    pinentry-curses
    (pass.withExtensions (exts: [ exts.pass-otp ]))

    # C/C++ source tooling
    clang-tools
    (runCommand "run-clang-tidy" { } ''
      mkdir -p $out/bin
      for cand in ${llvmPackages.clang-unwrapped}/bin/run-clang-tidy \
                  ${llvmPackages.clang-unwrapped.python}/bin/run-clang-tidy \
                  ${llvmPackages.clang-unwrapped.python}/share/clang/run-clang-tidy.py; do
        if [ -f "$cand" ]; then
          install -m755 "$cand" $out/bin/run-clang-tidy
          exit 0
        fi
      done
      echo "run-clang-tidy not found in clang-unwrapped outputs" >&2
      exit 1
    '')

    # CI runner
    act

    # ── Rootless podman ─────────────────────────────────────────────────────
    podman
    crun # OCI runtime (lighter than runc; default for rootless)
    conmon # container monitor process
    netavark # default network stack on podman 4+
    aardvark-dns # DNS for netavark networks
    slirp4netns # rootless user-mode networking
    passt # pasta backend (slirp4netns successor; podman picks it up)
    podman-compose
    # `docker` shell shim → podman.
    (writeShellScriptBin "docker" ''exec ${podman}/bin/podman "$@"'')

    # Editor/AI agent runtimes
    nodejs_24 # copilot-language-server requires Node 24 (see ai.lua)
    uv # for project tooling that asks for `uv`/`uvx`; brings no python
    python3Packages.ipython # interactive REPL; pulls its own python, only `ipython` lands on PATH

    # AI coding agents
    claude-code
    codex # OpenAI Codex CLI
    github-copilot-cli # `copilot`; prebuilt-binary derivation since 1.0.43
    tuicr # interactive git-change reviewer; flake input, see nix/flake.nix. Skill: dot_claude/skills/tuicr/
    aibox # Bubblewrap sandbox for AI coding agent sessions; flake input, see nix/flake.nix

    # ── LSPs / formatters / linters / DAPs ─────────────────────────────────
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
    vscode-langservers-extracted # cssls + html + jsonls + eslint
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

    # Zsh and plugins
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

  # Silence "X news items" banner on every `home-manager switch`.
  news.display = "silent";
}
