{ config, pkgs, lib, dotfilesRoot, ... }:

# VM-only Home-Manager profile (Ubuntu 22.04 remote-dev box). Adds
# Mason-related runtime carve-outs and the rootless podman stack on
# top of `common.nix`.

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
