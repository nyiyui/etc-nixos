{ config, qrystal, ... }: {
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
      tokenPath = config.age.secrets."kuromiya-hinanawi.qrystalct".path;
      azusa.networks.msb.name = config.networks.hostName;
    };
  };

  age.secrets."kuromiya-hinanawi.qrystalct".file = ../secrets/kuromiya-hinanawi.qrystalct.age;
}
