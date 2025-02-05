{ config, ... }:
{
  services.caddy = {
    enable = true;
    virtualHosts."https://eaasi-playground.nyiyui.ca" = {
      extraConfig = ''
        reverse_proxy http://10.8.0.107:80
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}

