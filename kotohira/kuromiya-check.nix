{ config, ... }: {
  security.acme = {
    acceptTerms = true;
    defaults.email = "+acme@nyiyui.ca";
  };
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    virtualHosts."kotohira.msb.q.nyiyui.ca" = {
      enableACME = true;
      addSSL = true;
      locations."/" = {
        extraConfig = ''
          add_header Content-Type 'text/plain; charset=utf-8';
          return 200 '黒宮経由で琴平に接続接続出来ました!';
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
