{
  description = "A haskell.nix flake";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";

    haskellNix = {
      url = "github:input-output-hk/haskell.nix";
      # workaround for nix 2.6.0 bug
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.follows = "haskellNix/nixpkgs-2111";

    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };

  outputs = { self, flake-utils, haskellNix, nixpkgs, pre-commit-hooks, ... }:
    let
      inherit (haskellNix) config;
      overlays = [
        haskellNix.overlay
        (import ./nix/haskell)
      ];
    in
    flake-utils.lib.eachSystem (import ./supported-systems.nix)
      (system:
        let
          pkgs = import nixpkgs { inherit system config overlays; };
          flake = pkgs.warp-hello-project.flake { };
          hsTools = pkgs.warp-hello-project.tools (import ./nix/haskell/tools.nix);
          pre-commit = pkgs.callPackage ./nix/pre-commit-hooks.nix { inherit pre-commit-hooks hsTools; };
        in
        nixpkgs.lib.recursiveUpdate flake {
          checks = {
            inherit (pre-commit) pre-commit-check;
          } // pkgs.lib.optionalAttrs (system == "x86_64-linux") {
            nixos-integration-test = pkgs.nixosTest {
              inherit system;

              nodes = {
                server = {
                  imports = [ ./nixos/modules/warp-hello.nix ];
                  nixpkgs.overlays = overlays;

                  networking.firewall.allowedTCPPorts = [ 80 ];
                  services.warp-hello = {
                    enable = true;
                    port = 80;
                  };
                };

                client = {
                  environment.systemPackages = [ pkgs.curl ];
                };
              };

              testScript = ''
                start_all()

                # wait for our service to be ready
                server.wait_for_open_port(80)

                # wait for networking and everything else to be ready
                client.wait_for_unit("multi-user.target")

                expected = "Hello world!"
                actual = client.succeed("curl http://server")
                assert expected == actual, "expected: \"{expected}\", but got \"{actual}\"".format(expected = expected, actual = actual)
              '';
            };
          };

          # so `nix build` will build the exe
          defaultPackage = flake.packages."warp-hello:exe:warp-hello";

          # so `nix run`  will run the exe
          defaultApp = {
            type = "app";
            program = "${flake.packages."warp-hello:exe:warp-hello"}/bin/warp-hello";
          };

          devShell =
            let
              update-materialized = pkgs.writeShellScriptBin "update-materialized" ''
                set -euo pipefail

                ${pkgs.warp-hello-project.plan-nix.passthru.calculateMaterializedSha} > nix/haskell/plan-sha256
                ${pkgs.warp-hello-project.plan-nix.passthru.generateMaterialized} nix/haskell/materialized
              '';
            in
            flake.devShell.overrideAttrs (attrs: {
              inherit (pre-commit) shellHook;

              buildInputs = attrs.buildInputs
              ++ [ update-materialized ]
              ++ pre-commit.shellBuildInputs;
            });

          legacyPackages = pkgs;
        }
      ) // {
      nixosModules = {
        warp-hello = {
          imports = [ ./nixos/modules/warp-hello.nix ];
          nixpkgs = { inherit overlays; };
        };
      };

      nixosConfigurations = {
        container = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = nixpkgs.lib.attrValues self.nixosModules ++ [
            {
              boot.isContainer = true;
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;
              networking = {
                firewall.allowedTCPPorts = [ 80 ];
                hostName = "warp-hello";
                useDHCP = false;
              };

              services.warp-hello = {
                enable = true;
                port = 80;
              };
            }
          ];
        };
      };
    };
}
