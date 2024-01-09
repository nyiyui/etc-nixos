{ config, pkgs, lib, ... }: let
  ula = "fda0:a4b2:2507::52";
in {
  systemd.services.unbound.wantedBy = lib.mkForce [];
  services.unbound = {
    enable = true;
  };
  services.unbound.settings = {
    server.interface = [ "127.0.0.55" ula ];
    server.access-control = [ "127.0.0.55 allow" "${ula} allow" ];
  };
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [
        "[${ula}]:53"
        "127.0.0.55:53"
      ];

      ipv6_servers = true;
      require_dnssec = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };
}
