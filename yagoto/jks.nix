{ config, specialArgs, ... }:
let
  jks = specialArgs.jks;
in
{
  systemd.services.jks = {
    script = ''
      source ${config.age.secrets.jks-config.path}
      ${jks}/bin/jks --port=0.0.0.0:8080
    '';
  };
  age.secrets.jks-config = {
    file = ../secrets/jks-config.sh.age;
  };
  age.secrets.origincert = {
    file = ../secrets/jks.nyiyui.ca.origincert.pem.age;
  };
  age.secrets.privkey = {
    file = ../secrets/jks.nyiyui.ca.privkey.pem.age;
  };
  services.caddy = {
    enable = true;
    virtualHosts."jks.nyiyui.ca" = {
      extraConfig = ''
        encode gzip
        reverse_proxy localhost:8080
        tls ${config.age.secrets.origincert.path} ${config.age.secrets.privkey.path}
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 ];
}
