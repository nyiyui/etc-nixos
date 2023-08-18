{ config, ... }: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "+acme@nyiyui.ca";
  };
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    virtualHosts."kotohira.msb.q.nyiyui.ca" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        extraConfig = ''
          add_header Content-Type 'text/plain; charset=utf-8';
          if ($server_addr = '10.59.0.0') {
            return 200 '黒宮経由で琴平に接続出来ました!';
          }
          return 200 'ネット経由で琴平に接続出来ました!';
        '';
      };
      locations."/ip" = {
        extraConfig = ''
          add_header Content-Type "application/json";
          return 200 '{"host":"$server_name","ip":"$remote_addr","port":"$remote_port","server_ip":"$server_addr","server_port":"$server_port"}\n';
        '';
      };
      locations."/autoupgrade-status/submit" = {
        extraConfig = ''
          limit_except POST {
            deny all;
          }
          proxy_set_header X-Real-IP $remote_addr;
          fastcgi_pass  unix:${config.services.phpfpm.pools.autoupgrade-status.socket};
          fastcgi_param SCRIPT_FILENAME ${./autoupgrade-status-submit.php};
        '';
      };
    };
  };
  services.phpfpm.pools.autoupgrade-status = {
    user = app;
    settings = {
      "listen.owner" = config.services.nginx.user;
      "pm" = "dynamic";
      "pm.max_children" = 32;
      "pm.max_requests" = 500;
      "pm.start_servers" = 2;
      "pm.min_spare_servers" = 2;
      "pm.max_spare_servers" = 5;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };
    phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
  };
}
