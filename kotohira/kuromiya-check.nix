{ config, ... }: {
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
    };
  };
}
