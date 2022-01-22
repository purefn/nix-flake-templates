{ haskell-nix
, compiler-nix-name ? "ghc902"
}:

haskell-nix.project {
  inherit compiler-nix-name;

  src = haskell-nix.haskellLib.cleanGit {
    name = "warp-hello-src";
    src = ../..;
  };
  index-state = "2022-01-17T00:00:00Z";
  plan-sha256 = builtins.readFile ./plan-sha256;
  materialized = ./materialized;
}

