{
  description = "Home-Manager profiles for the Arch host and the Ubuntu remote-dev VM.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      # Pin to the release branch matching nixpkgs lib.version (the
      # `nixos-unstable` snapshot we follow here reports 26.05). Without
      # this, HM master races ahead one cycle and emits the
      # "mismatched versions" warning at every activation. Bump the
      # branch name in lockstep when nixpkgs lib.version rolls over.
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # tuicr: TUI git-change reviewer. Upstream flake exposes
    # `packages.<system>.default`. Pulled here instead of nixpkgs because
    # it's not packaged there. The skill files under
    # `dot_claude/skills/tuicr/` rely on the `tuicr` binary being on PATH.
    tuicr = {
      url = "github:agavra/tuicr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, tuicr, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # Expose `pkgs.tuicr` so common.nix can list it next to other
          # packages without threading inputs into every module.
          (final: prev: { tuicr = tuicr.packages.${system}.default; })
        ];
        # Whitelist specific unfree packages (claude-code,
        # github-copilot-cli) instead of globally setting allowUnfree,
        # so a typo elsewhere can't silently pull in additional unfree
        # deps.
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude-code"
            "github-copilot-cli"
          ];
      };

      mkProfile = module: home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ module ];
        # Path to the cloned dotfiles checkout — passed in so the
        # modules can symlink shared configs from the same repo.
        extraSpecialArgs = {
          dotfilesRoot = ../.;
        };
      };
    in
    {
      homeConfigurations = {
        vm   = mkProfile ./vm.nix;
        host = mkProfile ./host.nix;
      };
    };
}
