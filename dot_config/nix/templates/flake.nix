{
  description = "Personal flake templates. Use: nix flake init -t ~/.config/nix/templates#<name>";

  outputs = { self }: {
    templates = {
      dev = {
        path = ./dev;
        description = "Generic per-project dev shell with direnv .envrc";
      };
      default = self.templates.dev;
    };
  };
}
