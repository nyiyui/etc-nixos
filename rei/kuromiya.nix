{ config, qrystal, ... }: {
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.node ];

  qrystal.services.cs = {
    enable = true;
    config.tls = {
      certPath = ../kuromiya-cert.pem;
      keyPath = config.age.secrets."kuromiya-key.pem".path;
    };
    tokens = [
      {
        name = "hinanawi";
        hash = "qrystalcth_5dfd42f22115f71c986b415404a954e91098f021bc394a7a298fa235611da6de";
        networks = [ "msb" ];
        canPull = true;
        canPush.networks.msb = {
          name = "hinanawi";
          canSeeElement = [];
        };
      }
    ];
  };

  age.secrets."kuromiya-key.pem".file = ../secrets/kuromiya-key.pem.age;
}
