{ config, specialArgs, ... }: let jks = specialArgs.jks; in
{
  systemd.services.jks = {
    script = ''
      source ${config.age.secrets.jks-config.path}
      ${jks}/bin/jks --port=0.0.0.0:80
    '';
  };
  age.secrets.jks-config = {
    file = ./secrets/jks-config.sh.age;
  };
  networking.firewall.allowedTCPPorts = [ 80 ];
}
