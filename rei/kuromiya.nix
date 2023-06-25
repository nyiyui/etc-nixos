{ config, qrystal, ... }: {
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.cs ];

  qrystal.services.cs = {
    enable = true;
    config.tls = {
      certPath = ../kuromiya-cert.pem;
      keyPath = config.age.secrets."kuromiya-key.pem".path;
    };
    config.tokens = [
      {
        name = "hinanawi";
        hash = "qrystalcth_5dfd42f22115f71c986b415404a954e91098f021bc394a7a298fa235611da6de";
        networks.msb = "hinanawi"; # 結び 君の名は
        canPull = true;
        canPush.networks.msb = {
          name = "hinanawi";
          canSeeElement = [];
        };
      }
    ];
    config.central.networks.msb = {
      keepalive = "30s";
      listenPort = 39570;
      ips = [ "10.59.0.0/8" ];
    };
  };

  # fw disbaled on GCE
  # networking.firewall.allowedUDPPorts = [ 39570 ];

  age.secrets."kuromiya-key.pem".file = ../secrets/kuromiya-key.pem.age;
}
