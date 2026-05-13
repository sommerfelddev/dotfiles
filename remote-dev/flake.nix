{
  description = "Headless dev environment for remote Ubuntu VMs.";

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
      pkgs = import nixpkgs { inherit system; config.allowUnfree = false; };
    in
    {
      homeConfigurations.vm = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
        # Path to the cloned dotfiles checkout — passed in so home.nix can
        # symlink shared configs (nvim, zellij, zsh) from the same repo.
        extraSpecialArgs = {
          dotfilesRoot = ../.;
        };
      };
    };
}
