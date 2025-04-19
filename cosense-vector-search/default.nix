{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kiyurica.services.cosense-vector-search;
in
{
  options.kiyurica.services.cosense-vector-search = {
    enable = lib.mkEnableOption "Vector search service for Cosense.";
    virtualHost = lib.mkOption {
      description = "Caddy virtual host the service will run at.";
      type = lib.types.str;
      example = "https://cosense-vector-search.example.com";
    };
    port = lib.mkOption {
      description = "Localhost port for Solr.";
      type = lib.types.port;
      default = 8983;
    };
  };
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.cosense-vector-search = {
      image = "library/solr:9.8.0-slim@sha256:fd236ed14ace4718c99d007d7c0360307ecba380ac4927abdf91fbf105804f28";
      ports = [ "127.0.0.1:${builtins.toString cfg.port}:8983" ];
      volumes = [
        "/var/lib/cosense-vector-search:/var/solr"
      ];
      cmd = [
        "solr"
        "-c"
      ];
    };
    systemd.services.${config.virtualisation.oci-containers.containers.cosense-vector-search.serviceName} =
      {
        serviceConfig = {
          StateDirectory = "cosense-vector-search";
          DynamicUser = true;
        };
      };

    services.caddy = {
      enable = true;
      virtualHosts.${cfg.virtualHost} = {
        extraConfig = ''
          basic_auth {
            kiyurica $2a$14$x2ZaCNUjl1Mf8.DORvBeVuDlw3W/8pZV.mR4j1MsMjWg3coaaatdW
          }
          reverse_proxy 127.0.0.1:${builtins.toString cfg.port}
        '';
      };
    };
  };
}
