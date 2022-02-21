{ haskell-nix
}:

haskell-nix.project {
  compiler-nix-name = "ghc902";

  src = haskell-nix.haskellLib.cleanGit {
    name = "warp-hello-src";
    src = ../..;
  };
  index-state = "2022-01-22T00:00:00Z";
  plan-sha256 = builtins.readFile ./plan-sha256;
  materialized = ./materialized;
}

