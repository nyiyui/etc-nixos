{ config, pkgs, qrystal, ... }:
let
  hostName = config.networking.hostName;
  hostsThatCanForward = [ "chocolate-lemon" ];
  ula = "fda0:a4b2:2507::52";
  hokutoAddr = "127.0.0.39";
in {
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.node ];

  systemd.services.qrystal-node.environment = {
    "QRYSTAL_LOGGING_CONFIG" = "development";
  };
  qrystal.services.node = {
    enable = true;
    config.trace = {
      outputPath = "/tmp/qrystal-trace";
      waitUntilCNs = [ "msb" ];
    };
    config.hokuto = {
      configureDnsmasq = false;
      addr = hokutoAddr;
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
        canForward = builtins.elem hostName hostsThatCanForward;
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

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [ "[${ula}]:53" "127.0.0.1:53" ];

      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;

      forwarding_rules = pkgs.writeText "dns-forwarding-rules.txt" ''
        q.nyiyui.ca ${hokutoAddr}
        umi 10.6.0.1
        kai 10.6.0.1
      '';

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy/public-resolvers.md";
        minisign_key =
          "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        refresh_delay = 72;
      };
    };
  };

  systemd.services.dnscrypt-proxy2.serviceConfig = {
    StateDirectory = "dnscrypt-proxy";
  };
}
