# haskell.nix tools configuration for use with `project.tools`.
# note: we don't add this directory to the shell in `project.nix`.
# instead, we configure them into the `devShell` directory so that
# we can reuse the same versions for the pre-commit-hooks
let
  # needs these overrides for ghc 9.0.2 so that exceptions and Cabal are reinstallable
  nonReinstallablePkgsModule =
    {
      nonReinstallablePkgs = [
        "rts"
        "ghc-heap"
        "ghc-prim"
        "integer-gmp"
        "integer-simple"
        "base"
        "deepseq"
        "array"
        "ghc-boot-th"
        "pretty"
        "template-haskell"
        # ghcjs custom packages
        "ghcjs-prim"
        "ghcjs-th"
        "ghc-bignum"
        "exceptions"
        "stm"
        "ghc-boot"
        "ghc"
        "Win32"
        "array"
        "binary"
        "bytestring"
        "containers"
        # "Cabal"
        "directory"
        "filepath"
        "ghc-boot"
        "ghc-compact"
        "ghc-prim"
        # "ghci" "haskeline"
        "hpc"
        "mtl"
        "parsec"
        "process"
        "text"
        "time"
        "transformers"
        "unix"
        "xhtml"
        "terminfo"
      ];
    };
in
{
  brittany = {
    version = "latest";
    cabalProject = ''
      packages: .
      allow-newer: multistate:base, data-tree-print:base, butcher:base
    '';
    modules = [ nonReinstallablePkgsModule ];
  };
  cabal-fmt = {
    version = "latest";
    # Punt on building cabal-fmt with ghc 9.0.2 for now. It builds with ghc 9.0.2
    # if we use `allow-newer: cabal-fmt:base`, but doesn't build against anything
    # newer than Cabal 3.2.1.0, and Cabal 3.2.1.0 cannot  be built with ghc 9.0.2.
    compiler-nix-name = "ghc8107";
  };
  cabal-install = "latest";
  ghcid = "latest";
  haskell-language-server = {
    version = "latest";
    modules = [
      {
        # to compile with support for brittany
        packages.haskell-language-server.configureFlags = [ "--flags=agpl" ];
      }
      nonReinstallablePkgsModule
    ];
    pkg-def-extras = [
      (hackage: {
        packages = {
          "Cabal" = (((hackage.Cabal)."3.6.2.0").revisions).default;
          "fourmolu" = (((hackage.fourmolu)."0.5.0.1").revisions).default;
          "ghc-lib-parser" = (((hackage.ghc-lib-parser)."9.2.1.20220109").revisions).default;
          "ormolu" = (((hackage.ormolu)."0.4.0.0").revisions).default;
        };
      })
    ];
  };
  hlint = {
    version = "latest";
    modules = [ nonReinstallablePkgsModule ];
  };
}

