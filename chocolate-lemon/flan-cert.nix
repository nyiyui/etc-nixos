{ config, pkgs, ... }: {
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    virtualHosts."chocolate-lemon.msb.q.nyiyui.ca" = {
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
    virtualHosts."flan.msb.q.nyiyui.ca" = {
      enableACME = true;
      forceSSL = true;
    };
  };

  systemd.services.flan-cert = {
    after = [ "acme-flan.msb.q.nyiyui.ca.service" ];
    script = ''
      ${pkgs.openssh}/bin/scp -o StrictHostKeyChecking=accept-new -i ${
        config.age.secrets."flan-cert.id_ed25519".path
      } /var/lib/acme/flan.msb.q.nyiyui.ca/fullchain.pem flan-cert@flan.msb.q.nyiyui.ca:/home/flan-cert
      ${pkgs.openssh}/bin/scp -o StrictHostKeyChecking=accept-new -i ${
        config.age.secrets."flan-cert.id_ed25519".path
      } /var/lib/acme/flan.msb.q.nyiyui.ca/key.pem flan-cert@flan.msb.q.nyiyui.ca:/home/flan-cert
    '';
    unitConfig.StartLimitIntervalSec = 300;
    unitConfig.StartLimitBurst = 5;
    serviceConfig.Nice = 19;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 30;
  };

  users.users.flan-cert = {
    isSystemUser = true;
    description = "Uploads CA certificates to Flan";
    group = "flan-cert";
  };
  users.groups.flan-cert = { };
  age.secrets."flan-cert.id_ed25519" = {
    file = ../secrets/chocolate-lemon-flan-cert.id_ed25519.age;
    owner = "flan-cert";
    group = "flan-cert";
    mode = "400";
  };
}
