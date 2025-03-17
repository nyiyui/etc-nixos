{ ... }: let
  port = "8714";
in {
  systemd.services.polar-data-collector-server = {
    script = ''
      /nix/store/0xc00l44hi7z10zp7xdvvg6xkwh6326n-polar-data-collector/bin/server -addr localhost:${port}
    '';
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
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
