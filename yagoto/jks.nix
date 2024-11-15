{ config, specialArgs, ... }:
let
  jks = specialArgs.jks;
in
{
  users.groups.jks = { };
  users.users.jks = {
    isSystemUser = true;
    description = "JKS services";
    group = "jks";
  };
  systemd.services.jks = {
    script = ''
      source ${config.age.secrets.jks-config.path}
      ${jks.outputs.packages.aarch64-linux.jks}/bin/server --port=0.0.0.0:8080
    '';
    serviceConfig.User = "jks";
  };
  age.secrets.jks-config = {
    file = ../secrets/jks-config.sh.age;
    owner = "jks";
    mode = "400";
  };
  age.secrets.origincert = {
    file = ../secrets/jks.nyiyui.ca.origincert.pem.age;
    owner = "caddy";
    mode = "400";
  };
  age.secrets.privkey = {
    file = ../secrets/jks.nyiyui.ca.privkey.pem.age;
    owner = "caddy";
    mode = "400";
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
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
