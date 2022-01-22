{
  description = "A haskell.nix flake";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";

    haskellNix.url = "github:input-output-hk/haskell.nix";

    nixpkgs.follows = "haskellNix/nixpkgs";

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
        in
        nixpkgs.lib.recursiveUpdate flake {
          checks = {
            pre-commit-check = pre-commit-hooks.lib.${system}.run {
              src = ./.;
              hooks =
                let
                  excludeMaterialized = {
                    enable = true;
                    excludes = [ "nix/haskell/materialized/" ];
                  };
                in
                {
                  brittany = {
                    enable = true;
                    entry = pkgs.lib.mkForce "${hsTools.brittany}/bin/brittany --write-mode=inplace";
                  };
                  cabal-fmt = {
                    enable = true;
                    entry = pkgs.lib.mkForce "${hsTools.cabal-fmt}/bin/cabal-fmt --inplace";
                  };
                  hlint = {
                    enable = true;
                    entry = pkgs.lib.mkForce "${hsTools.hlint}/bin/hlint";
                  };
                  nix-linter = excludeMaterialized;
                  nixpkgs-fmt = excludeMaterialized;
                };
            };
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
              inherit (self.checks.${system}.pre-commit-check) shellHook;

              buildInputs = attrs.buildInputs
              ++ [ update-materialized ]
              ++ (with pre-commit-hooks.packages.${system}; [
                nixpkgs-fmt
                nix-linter
              ])
              ++ (builtins.attrValues hsTools);
            });

          legacyPackages = pkgs;
        }
      ) // {
      nixosModules = {
        warp-hello = {
          imports = [ ./nixos/modules/warp-hello.nix ];
          nixpkgs.overlays = overlays;
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
