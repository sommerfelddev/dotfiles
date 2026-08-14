{
  description = "Home-Manager profiles for the Arch host and the Ubuntu remote-dev VM.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      # Track the Home Manager branch whose release.json matches nixpkgs'
      # lib.version. nixos-unstable currently reports 26.11pre-git, while
      # home-manager's latest release branch is still 26.05, so master is the
      # matching input until release-26.11 exists.
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # tuicr: TUI git-change reviewer. Upstream flake exposes
    # `packages.<system>.default`. Pulled here instead of nixpkgs because
    # it's not packaged there. The skill files under
    # `dot_claude/skills/tuicr/` rely on the `tuicr` binary being on PATH.
    tuicr = {
      url = "github:ruifm/tuicr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aibox = {
      url = "github:ruifm/aibox";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      tuicr,
      aibox,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # Expose external flake packages so common.nix can list them next to
          # nixpkgs packages without threading inputs into every module.
          (final: prev: {
            tuicr = tuicr.packages.${system}.default;
            aibox = aibox.packages.${system}.default;
          })
        ];
        # Whitelist specific unfree packages (claude-code,
        # github-copilot-cli) instead of globally setting allowUnfree,
        # so a typo elsewhere can't silently pull in additional unfree
        # deps.
        config.allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "claude-code"
            "github-copilot-cli"
          ];
      };

      mkProfile =
        module:
        home-manager.lib.homeManagerConfiguration {
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
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          basedpyright
          just
          nixfmt
          prettier
          ruff
          selene
          shellcheck
          shfmt
          stylua
          taplo
        ];
      };

      homeConfigurations = {
        vm = mkProfile ./vm.nix;
        host = mkProfile ./host.nix;
      };
    };
}
