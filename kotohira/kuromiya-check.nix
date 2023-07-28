{ config, ... }:
{
  services.nginx = {
    enable = true;
    virtualHosts."kotohira.msb.q.nyiyui.ca" = {
      sslCertificate = config.age.secrets."kotohira-kuromiya-check-cert.pem".path;
      sslCertificateKey = config.age.secrets."kotohira-kuromiya-check-key.pem".path;
      addSSL = true;
      locations."/" = {
        extraConfig = ''
          add_header Content-Type text/plain;
          return 200 '黒宮経由で琴平に接続接続出来ました!'
        '';
      };
    };
  };
  age.secrets."kotohira-kuromiya-check-cert.pem" = {
    file = ../secrets/kotohira-kuromiya-check-cert.pem.age;
    owner = config.services.nginx.user;
    mode = "400";
  };
  age.secrets."kotohira-kuromiya-check-key.pem" = {
    file = ../secrets/kotohira-kuromiya-check-key.pem.age;
    owner = config.services.nginx.user;
    mode = "400";
  };
}
