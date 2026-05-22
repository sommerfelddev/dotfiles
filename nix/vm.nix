{ config, pkgs, lib, dotfilesRoot, ... }:

# VM-only Home-Manager profile (Ubuntu 22.04 remote-dev box). Adds the
# rootless podman stack, the editor/zellij/zsh/git config symlinks
# back into the cloned dotfiles tree, and a minimal ~/.zshenv shim —
# all of which the Arch host gets from chezmoi instead.

let
  dotfiles = "${builtins.getEnv "HOME"}/.local/share/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in
{
  imports = [ ./common.nix ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.sessionVariables = {
    # Ubuntu 20.04-derived hosts still default to cgroups v1; podman 5
    # warns on every invocation. Flipping to v2 is a host-level reboot
    # and only matters for --memory/--cpus, so silence the warning.
    PODMAN_IGNORE_CGROUPSV1_WARNING = "1";
  };

  home.packages = with pkgs; [
    # ── Rootless podman ─────────────────────────────────────────────────────
    # The nix `podman` is wrapped to find these helpers via /nix/store
    # paths, so we don't need to write a containers.conf for
    # `helper_binaries_dir`.
    podman
    crun         # OCI runtime (lighter than runc; default for rootless)
    conmon       # container monitor process
    netavark     # default network stack on podman 4+
    aardvark-dns # DNS for netavark networks
    slirp4netns  # rootless user-mode networking
    passt        # pasta backend (slirp4netns successor; podman picks it up)
  ];

  # ── Shared config symlinks ──────────────────────────────────────────────────
  # Live symlinks back into the cloned working tree so `git pull` is enough
  # to update configs — no `home-manager switch` required after every edit.
  # On the Arch host the same files are deployed by chezmoi; this block
  # exists because the VM doesn't run chezmoi.
  #
  # INVARIANT: every program that is both (a) installed by `nix/common.nix`
  # and (b) has a config tree under `dot_config/<name>/` MUST appear here.
  # Otherwise the VM silently uses the tool's defaults while the host runs
  # the tracked config — drift that's hard to spot. See
  # `.github/copilot-instructions.md` (§ Nix VM symlink invariant).
  xdg.configFile = {
    # Editor + multiplexer + terminal
    "nvim".source             = link "dot_config/nvim";
    "zellij".source           = link "dot_config/zellij";
    "ghostty".source          = link "dot_config/ghostty";   # for terminfo refs only

    # Shells
    "zsh/.zshrc".source       = link "dot_config/zsh/dot_zshrc";
    "zsh/.zprofile".source    = link "dot_config/zsh/dot_zprofile";
    "direnv/direnvrc".source  = link "dot_config/direnv/direnvrc";

    # Git
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

    # Leaf CLI tools whose binary lives in nix/common.nix
    "bat/config".source       = link "dot_config/bat/config";
    "lsd/config.yaml".source  = link "dot_config/lsd/config.yaml";
    "yazi".source             = link "dot_config/yazi";
    "ripgrep/ripgreprc".source = link "dot_config/ripgrep/ripgreprc";
    "fd/ignore".source        = link "dot_config/fd/ignore";
    "wget/wgetrc".source      = link "dot_config/wget/wgetrc";
    "npm/npmrc".source        = link "dot_config/npm/npmrc";
    "ipython/profile_default/ipython_config.py".source =
      link "dot_config/ipython/profile_default/ipython_config.py";

    # Debug / build tooling
    "gdb/gdbinit".source      = link "dot_config/gdb/gdbinit";
    "gdb/gdbearlyinit".source = link "dot_config/gdb/gdbearlyinit";
    "clangd/config.yaml".source = link "dot_config/clangd/config.yaml";
    "ccache/ccache.conf".source = link "dot_config/ccache/ccache.conf";
  };

  # Claude-code looks under ~/.claude (NOT XDG). Skills live there.
  # Symlink the whole tuicr skill directory so SKILL.md and the wrapper
  # script (chezmoi `executable_` prefix preserved → see the dispatch
  # comment in SKILL.md) are picked up together.
  home.file.".claude/skills/tuicr/SKILL.md".source =
    link "dot_claude/skills/tuicr/SKILL.md";
  home.file.".claude/skills/tuicr/tuicr-wrapper.sh".source =
    link "dot_claude/skills/tuicr/executable_tuicr-wrapper.sh";

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
}
