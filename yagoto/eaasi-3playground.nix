{ config, ... }:
{
  age.secrets.eaasi-3playground-origincert = {
    file = ../secrets/eaasi-3playground.nyiyui.ca.origincert.pem.age;
    owner = "caddy";
    mode = "400";
  };
  age.secrets.eaasi-3playground-privkey = {
    file = ../secrets/eaasi-3playground.nyiyui.ca.privkey.pem.age;
    owner = "caddy";
    mode = "400";
  };
  services.caddy = {
    enable = true;
    virtualHosts."https://eaasi-3playground.nyiyui.ca" = {
      extraConfig = ''
        reverse_proxy http://10.8.0.107:80
        tls ${config.age.secrets.eaasi-3playground-origincert.path} ${config.age.secrets.eaasi-3playground-privkey.path}
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
