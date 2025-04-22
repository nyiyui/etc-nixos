{ config, pkgs, specialArgs, ... }:
let port = "8714";
in {
  systemd.services.polar-data-collector-server = {
    script = ''
      ${
        specialArgs.polar-data-collector.packages.${pkgs.system}.server
      }/bin/server -addr localhost:${port} -db $STATE_DIRECTORY/db.sqlite3
    '';
    serviceConfig.StateDirectory = "polar-data-collector-server";
    wantedBy = [ "multi-user.target" ];
  };
  age.secrets.gtxr-vrsa-origincert = {
    file = ../secrets/gtxr-vrsa.kiyuri.ca.origincert.pem.age;
    owner = "caddy";
    mode = "400";
  };
  age.secrets.gtxr-vrsa-privkey = {
    file = ../secrets/gtxr-vrsa.kiyuri.ca.privkey.pem.age;
    owner = "caddy";
    mode = "400";
  };
  services.caddy = {
    virtualHosts."gtxr-vrsa.kiyuri.ca" = {
      extraConfig = ''
        reverse_proxy localhost:${port}
        tls ${config.age.secrets.gtxr-vrsa-origincert.path} ${config.age.secrets.gtxr-vrsa-privkey.path}
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
