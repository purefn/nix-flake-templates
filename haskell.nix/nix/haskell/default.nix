final:

let
  warp-hello-project = final.callPackage ./project.nix { };
in
_prev:
{
  inherit warp-hello-project;
  inherit (warp-hello-project.warp-hello.components.exes) warp-hello;
}
