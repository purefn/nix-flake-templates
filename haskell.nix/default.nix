{ system ? builtins.currentSystem
}:

let
  # get the inputs out of `flake.lock`
  flake = import ./nix/flake-compat.nix { inherit system; };
in
flake.defaultNix.legacyPackages.${system}.warp-hello-project
