{ config, qrystal, ... }:
let
  hostName = config.networking.hostName;
  hostsThatCanForward = [
    "kotohira"
  ];
in {
  imports = [
    qrystal.outputs.nixosModules.x86_64-linux.node
    ./dns.nix
  ];

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

  services.dnsmasq.settings.server = [
    "127.0.0.55"
    "fda0:a4b2:2507::52"
    # local
    "/umi/10.6.0.1"
    "/kai/10.6.0.1"
  ];
  services.dnsmasq.settings.local = "/local/";
}
