{ ... }:

# VM-only Home-Manager package profile.
{
  imports = [ ./common.nix ];

  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  home.sessionVariables = {
    PODMAN_IGNORE_CGROUPSV1_WARNING = "1";
  };

  home.packages = [ ];
}
