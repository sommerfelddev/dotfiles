{
  description = "Home-Manager profiles for the Arch host and the Ubuntu remote-dev VM.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
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
