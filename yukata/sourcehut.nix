{ config, ... }:
let
  fqdn = "srht.kiyuri.ca";
in
{
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  services.postgresql = {
    enable = true;
  };

  services.sourcehut = {
    enable = true;
    meta.enable = true;
    meta.port = 5001;
    git.enable = true;
    git.port = 5002;
    #man.enable = true;
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
        owner-name = "Ken Shibata";
        owner-email = "ken.shibata@nyiyui.ca";
        site-name = "sourcehut";
      };
      mail = {
        #pgp-key-id = "todo";
        #pgp-privkey = config.age.secrets.sourcehut-gpg-privkey.path;
        #pgp-pubkey = "${./sourcehut-gpg-pubkey.pem}";
        smtp-from = "srht@srht.kiyuri.ca";
        smtp-host = "srht@srht.kiyuri.ca";
      };
      webhooks.private-key = config.age.secrets.sourcehut-webhook-key.path;
      "git.sr.ht" = {
        oauth-client-id = "76d5d8fd-9f50-4e49-9f30-b668dc3b9478";
        oauth-client-secret = config.age.secrets.sourcehut-gitsrht-oauth-client-secret.path;
      };
    };
  };

  services.openssh.settings = {
    AuthorizedKeysCommand = ''/run/current-system/sw/bin/gitsrht-dispatch "%u" "%h" "%t" "%k"'';
    AuthorizedKeysCommandUser = "root";
    PermitUserEnvironment = "SRHT_*";
  };

  systemd.services.metasrht-api.serviceConfig.BindReadOnlyPaths = [
    config.age.secrets.sourcehut-gpg-privkey.path
  ];

  systemd.services.gitsrht-api.serviceConfig.BindReadOnlyPaths = [
    config.age.secrets.sourcehut-gpg-privkey.path
  ];

  security.acme.acceptTerms = true;
  security.acme.certs."${fqdn}" = {
    email = "srht+acme@nyiyui.ca";
    extraDomainNames = [
      "meta.${fqdn}"
      "man.${fqdn}"
      "git.${fqdn}"
    ];
  };

  services.nginx = {
    enable = true;
    # only recommendedProxySettings are strictly required, but the rest make sense as well.
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    # Settings to setup what certificates are used for which endpoint.
    virtualHosts = {
      "${fqdn}".enableACME = true;
      "meta.${fqdn}".useACMEHost = fqdn;
      "man.${fqdn}".useACMEHost = fqdn;
      "git.${fqdn}".useACMEHost = fqdn;
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

  age.secrets.sourcehut-gpg-privkey = {
    file = ../secrets/sourcehut-gpg-privkey.pem.age;
    owner = config.services.sourcehut.meta.user;
    # do not include config.services.sourcehut.meta.group here! only user is for secrets.
    mode = "0600";
  };

  age.secrets.sourcehut-gitsrht-oauth-client-secret = {
    file = ../secrets/sourcehut-gitsrht-oauth-client-secret.age;
  };
}
