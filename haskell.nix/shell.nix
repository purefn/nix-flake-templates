{ system ? builtins.currentSystem }:

(import ./nix/flake-compat.nix { inherit system; }).shellNix
