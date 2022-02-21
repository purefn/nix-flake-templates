{ findutils, hsTools, pre-commit-hooks, system, writeShellScriptBin }:

let
  # overrides brittany, hlint, etc. to be the same as those in our dev shell
  tools = pre-commit-hooks.packages.${system} // hsTools;
  pre-commit-check = pre-commit-hooks.lib.${system}.run {
    inherit tools;

    src = ./..;
    excludes = [
      "nix/haskell/materialized/"
      "dist-newstyle/"
    ];
    hooks =
      {
        brittany.enable = true;
        cabal-fmt.enable = true;
        hlint.enable = true;
        nix-linter.enable = true;
        nixpkgs-fmt.enable = true;
      };
  };

  format = writeShellScriptBin "format" ''
    set -euo pipefail

    ${findutils}/bin/find . -name '*.hs' -not -path './dist-newstyle/*' \
      | xargs ${tools.brittany}/bin/brittany --write-mode=inplace

    ${findutils}/bin/find . -name '*.cabal' -not -path './dist-newstyle/*' \
      | xargs ${tools.cabal-fmt}/bin/cabal-fmt --inplace

    ${findutils}/bin/find . -name '*.nix' -not -path './nix/haskell/materialized/*' \
      | xargs ${tools.nixpkgs-fmt}/bin/nixpkgs-fmt
  '';
in
{
  inherit pre-commit-check;
  inherit (pre-commit-check) shellHook;

  shellBuildInputs =
    [ format ]
    ++ (with pre-commit-hooks.packages.${system}; [
      nixpkgs-fmt
      nix-linter
    ])
    ++ (builtins.attrValues hsTools);
}

