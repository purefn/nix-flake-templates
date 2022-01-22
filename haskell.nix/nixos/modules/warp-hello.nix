{ config, pkgs, lib ? pkgs.lib, ... }:

let
  cfg = config.services.warp-hello;
in
{
  options = {
    services.warp-hello = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to run the warp-hello server.
        '';
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 8080;
        description = ''
          Port the server will listen for HTTP requests on.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.warp-hello = {
      wantedBy = [ "multi-user.target" ];
      environment = {
        PORT = toString cfg.port;
      };
      serviceConfig = {
        ExecStart = "@${pkgs.warp-hello}/bin/warp-hello warp-hello";
      };
    };
  };
}

