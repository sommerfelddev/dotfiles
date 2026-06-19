{ ... }:

# VM-only Home-Manager profile (Ubuntu remote-dev box). This installs the
# shared tool profile and VM session variables only; dotfile deployment is
# owned by chezmoi, matching the Arch host.
{
  imports = [ ./common.nix ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.sessionVariables = {
    # Ubuntu 20.04-derived hosts still default to cgroups v1; podman 5
    # warns on every invocation. Flipping to v2 is a host-level reboot
    # and only matters for --memory/--cpus, so silence the warning.
    # (Arch host is on cgroups v2, so this isn't set in common.nix.)
    PODMAN_IGNORE_CGROUPSV1_WARNING = "1";
  };

  # No extra packages — the rootless podman stack now lives in
  # `common.nix` so the host and VM share the same nix-pinned versions.
  home.packages = [ ];
}
