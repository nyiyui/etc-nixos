{ config, qrystal, ... }:
let
  hostName = config.networking.hostName;
in {
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.node ];

  qrystal.services.node = {
    enable = true;
    config.hokuto = {
      configureDnsmasq = true;
      addr = "127.0.0.39";
      parent = ".qrystal.internal";
    };
    config.cs = {
      comment = "kuromiya";
      endpoint = "kuromiya.nyiyui.ca:39252";
      tls.certPath = ../kuromiya-cert.pem;
      networks = [ "msb" ];
      tokenPath = config.age.secrets."kuromiya-${hostName}.qrystalct".path;
      azusa.networks.msb.name = hostName;
    };
  };

  age.secrets."kuromiya-${hostName}.qrystalct".file = ../secrets/kuromiya-${hostName}.qrystalct.age;
}
