{ qrystal, ... }:
{ 
  imports = [ qrystal.outputs.nixosModules.x86_64-linux.node ];

  qrystal.services.node = {
    enable = true;
    config.css = [ {
      comment = "gensokyo";
      endpoint = "gensokyo.mcpt.nyiyui.ca:39252";
      tls.certPath = builtins.toFile "gensokyo-cert.pem" (builtins.readFile ./gensokyo-cert.pem);
      networks = [ "hakurei" ];
      tokenPath = "/etc/nixos/gensokyo-token";
    } ];
  };
}
