{ config, ... }:
let
  fqdn = "srht.kiyuri.ca";
in
{
  networking.firewall.allowedTCPPorts = [ 443 ];

  services.postgresql = {
    enable = true;
  };

  services.sourcehut = {
    enable = true;
    #git.enable = true;
    #man.enable = true;
    meta.enable = true;
    nginx.enable = true;
    # postfix.enable = true; # no money for email lol
    postgresql.enable = true;
    redis.enable = true;
    settings = {
      "sr.ht" = {
        environment = "production";
        global-domain = fqdn;
        origin = "https://${fqdn}";
        # Produce keys with srht-keygen from sourcehut.coresrht.
        network-key = config.age.secrets.sourcehut-network-key.path;
        service-key = config.age.secrets.sourcehut-service-key.path;
      };
      mail = {
        pgp-key-id = "todo";
        pgp-privkey = "/tmp/todo";
        pgp-pubkey = "/tmp/todo";
        smtp-from = "srht@srht.kiyuri.ca";
        smtp-host = "srht@srht.kiyuri.ca";
      };
      webhooks.private-key = config.age.secrets.sourcehut-webhook-key.path;
    };
  };

  services.nginx = {
    enable = true;
    # only recommendedProxySettings are strictly required, but the rest make sense as well.
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    # Settings to setup what certificates are used for which endpoint.
    virtualHosts =
      let
        conf = {
          sslCertificate = config.age.secrets.sourcehut-origincert.path;
          sslCertificateKey = config.age.secrets.sourcehut-privkey.path;
        };
      in
      {
        "${fqdn}" = conf;
        "meta.${fqdn}" = conf;
        "man.${fqdn}" = conf;
        "git.${fqdn}" = conf;
      };
  };

  age.secrets.sourcehut-network-key = {
    file = ../secrets/sourcehut-network-key.age;
  };

  age.secrets.sourcehut-service-key = {
    file = ../secrets/sourcehut-service-key.age;
  };

  age.secrets.sourcehut-webhook-key = {
    file = ../secrets/sourcehut-webhook-key.age;
  };

  age.secrets.sourcehut-origincert = {
    file = ../secrets/sourcehut-origincert.pem.age;
    owner = config.services.nginx.user;
    mode = "400";
  };

  age.secrets.sourcehut-privkey = {
    file = ../secrets/sourcehut-privkey.pem.age;
    owner = config.services.nginx.user;
    mode = "400";
  };
}
