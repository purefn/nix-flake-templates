{
  description = "Nix flake templates";

  outputs = { ... }: {
    templates = {
      haskell-nix = {
        path = ./haskell.nix;
        description = "haskell.nix development flake";
      };
    };
  };
}
