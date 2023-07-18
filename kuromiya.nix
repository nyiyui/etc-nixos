{ config, qrystal, ... }:
let
  hostName = config.networking.hostName;
  dnscryptHost = "127.0.0.80";
in {
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.node ];

  systemd.services.qrystal-node.environment = {
    "DEBUG_LEVEL" = "debug";
  };
  qrystal.services.node = {
    enable = true;
    config.trace = {
      outputPath = "/tmp/qrystal-trace";
      waitUntilCNs = [ "msb" ];
    };
    config.hokuto = {
      configureDnsmasq = true;
      addr = "127.0.0.39";
      parent = ".q.nyiyui.ca";
    };
    config.cs = {
      comment = "kuromiya";
      endpoint = "kuromiya.nyiyui.ca:39252";
      tls.certPath = ./kuromiya-cert.pem;
      networks = [ "msb" ];
      tokenPath = config.age.secrets."kuromiya-${hostName}.qrystalct".path;
      azusa.networks.msb = {
        name = hostName;
        # canSee is blank = can see any
      };
    };
  };

  age.secrets."kuromiya-${hostName}.qrystalct" = {
    file = ./secrets/kuromiya-${hostName}.qrystalct.age;
    owner = "qrystal-node";
    group = "qrystal-node";
    mode = "400";
  };

  services.dnsmasq.settings.server = [ dnscryptHost ];
    services.dnsmasq.settings.local = "/local/";
  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [ "${dnscryptHost}:53" ]; # TODO IPv6
      require_dnssec = true;
      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          "https://ipv6.download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "public-resolvers.md";
        minisign_key =
          "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        refresh_delay = 72;
        prefix = "";
      };
    };
  };
}
