{ config, qrystal, ... }: {
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.node ];

  qrystal.services.node = {
    enable = true;
    config.hokuto = {
      addr = "";
      useInConfig = false;
    };
    config.cs = {
    comment = "kimihenokore";
      endpoint = "qrystal.nyiyui.ca:39252";
      tls.certPath = builtins.toFile "kimihenokore-cert.pem"
        (builtins.readFile ./kimihenokore-cert.pem);
      networks = [ "haruka" ];
      tokenPath = "/etc/nixos/kimihenokore-token";
      azusa.networks.haruka = { name = config.networking.hostName; };
    };
  };
}
