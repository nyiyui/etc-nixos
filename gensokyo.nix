{ config, qrystal, ... }:
{ 
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.node ];

  qrystal.services.node = {
    enable = true;
    config.css = [
      #{
      #  comment = "gensokyo";
      #  endpoint = "gensokyo.mcpt.nyiyui.ca:39252";
      #  tls.certPath = builtins.toFile "gensokyo-cert.pem" (builtins.readFile ./gensokyo-cert.pem);
      #  networks = [ "hakurei" ];
      #  tokenPath = "/etc/nixos/gensokyo-token";
      #  azusa.networks.hakurei = {
      #    name = config.networking.hostname;
      #  };
      #}
      {
        comment = "kimihenokore";
        endpoint = "qrystal.nyiyui.ca:39252";
        tls.certPath = builtins.toFile "kimihenokore-cert.pem" (builtins.readFile ./kimihenokore-cert.pem);
        networks = [ "haruka" ];
        tokenPath = "/etc/nixos/kimihenokore-token";
        azusa.networks.haruka = {
          name = config.networking.hostname;
        };
      }
    ];
  };
}
