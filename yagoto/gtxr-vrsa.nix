{ ... }: let
  port = "8714";
in {
  systemd.services.polar-data-collector-server = {
    script = ''
      /nix/store/0xc00l44hi7z10zp7xdvvg6xkwh6326n-polar-data-collector/bin/server -addr localhost:${port}
    '';
    wantedBy = [ "multi-user.target" ];
  };
  services.caddy = {
    virtualHosts."gtxr-vrsa.kiyuri.ca" = {
      extraConfig = ''
        reverse_proxy localhost:${port}
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
