{ config, ... }: {
  age.secrets.eaasi-playground-origincert = {
    file = ../secrets/eaasi-playground.nyiyui.ca.origincert.pem.age;
    owner = "caddy";
    mode = "400";
  };
  age.secrets.eaasi-playground-privkey = {
    file = ../secrets/eaasi-playground.nyiyui.ca.privkey.pem.age;
    owner = "caddy";
    mode = "400";
  };
  services.caddy = {
    enable = true;
    virtualHosts."https://eaasi-playground.nyiyui.ca" = {
      extraConfig = ''
        reverse_proxy http://10.8.0.106:80
        tls ${config.age.secrets.jks-origincert.path} ${config.age.secrets.jks-privkey.path}
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
