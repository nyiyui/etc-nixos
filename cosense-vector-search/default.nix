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
    queryServerPort = lib.mkOption {
      description = "Localhost port for the query server (calls OpenAI to get a vector, and then does vector search).";
      type = lib.types.port;
      default = 45326;
    };
  };
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.cosense-vector-search = {
      image = "library/solr:9.8.0-slim@sha256:fd236ed14ace4718c99d007d7c0360307ecba380ac4927abdf91fbf105804f28";
      ports = [ "127.0.0.1:${builtins.toString cfg.port}:8983" ];
      volumes = [ "/portable0/cosense-vector-search/solr:/var/solr" ];
      cmd = [ "-c" ];
    };

    systemd.services.cosense-vector-search-query-server =
      let
        python = pkgs.python3.withPackages (
          ps: with ps; [
            aiohttp
            openai
            requests
          ]
        );
      in
      {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ]; # network required to access OpenAI
        description = "server to query OpenAI and do vector search";
        environment = {
          PORT = "${builtins.toString cfg.queryServerPort}";
        };
        serviceConfig = {
          DynamicUser = true;
          PrivateTmp = true;
          ExecStart = pkgs.writeShellScriptBin "cosense-vector-search-query-server" ''
            source ${config.age.secrets.cosense-vector-search-query-server.path}
            ${python}/bin/python3 ${./server.py}
          '';
        };
      };
    age.secrets.cosense-vector-search-query-server = {
      file = ../secrets/cosense-vector-search-query-server.env.age;
    };

    services.caddy = {
      enable = true;
      virtualHosts.${cfg.virtualHost} = {
        extraConfig = ''
          handle_path /query {
            basic_auth {
              kiyurica $2a$14$Q3pOoqbOiMvxQzPBFJU9UugGCtGjfYWoB70y/LJQw/GdpDriCy.Ce
            }
            reverse_proxy 127.0.0.1:${builtins.toString cfg.queryServerPort}
          }
          handle {
            basic_auth {
              kiyurica $2a$14$x2ZaCNUjl1Mf8.DORvBeVuDlw3W/8pZV.mR4j1MsMjWg3coaaatdW
            }
            reverse_proxy 127.0.0.1:${builtins.toString cfg.port}
          }
        '';
      };
    };
  };
}
