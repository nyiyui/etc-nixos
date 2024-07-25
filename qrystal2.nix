{ config, pkgs, qrystal2, ... }:
let
  hostName = config.networking.hostName;
  secretName = "qrystal2-irinaka.qrystalct";
  ula = "fda0:a4b2:2507::52";
  qrystalDNSAddr = "127.0.0.39";
in {
  imports = [ qrystal2.outputs.nixosModules.x86_64-linux.default ];

  environment.systemPackages = with pkgs; [ wireguard-tools ]; # for debugging

  services.qrystal-device-client = {
    enable = true;
    config.Clients.irinaka = {
      BaseURL = "https://irinaka.nyiyui.ca:39390";
      TokenPath = config.age.secrets.${secretName}.path;
      Network = "miti";
      Device = hostName;
      MinimumInterval = "60s";
    };
    config.dns.enable = true;
    config.dns.Parents = [
      { Suffix = ".qrystal.internal"; }
      { Suffix = ".q.nyiyui.ca"; }
    ];
  };
  systemd.services.qrystal-device-client.environment.QRYSTAL_LOGGING_CONFIG = "development";
  age.secrets.${secretName} = {
    file = ./secrets/qrystal2-irinaka-${hostName}.qrystalct.age;
    owner = "qrystal-device";
    group = "qrystal-device";
    mode = "400";
  };
  networking.firewall.allowedUDPPorts = [ 60408 ];

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [ "[${ula}]:53" "127.0.0.1:53" ];

      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;

      forwarding_rules = pkgs.writeText "dns-forwarding-rules.txt" ''
        q.nyiyui.ca ${qrystalDNSAddr}
        qrystal.internal ${qrystalDNSAddr}
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

  home-manager.users.nyiyui = {
    nyiyui.qrystal2 = true;
  };
}
