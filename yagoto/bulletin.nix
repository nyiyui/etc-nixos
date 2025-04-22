{ config, ... }: {
  age.secrets.bulletin-origincert = {
    file = ../secrets/bulletin.nyiyui.ca.origincert.pem.age;
    owner = "caddy";
    mode = "400";
  };
  age.secrets.bulletin-privkey = {
    file = ../secrets/bulletin.nyiyui.ca.privkey.pem.age;
    owner = "caddy";
    mode = "400";
  };
  services.caddy = {
    enable = true;
    virtualHosts."https://bulletin.nyiyui.ca" = {
      extraConfig = ''
        root /portable0/bulletin
        file_server browse
        tls ${config.age.secrets.bulletin-origincert.path} ${config.age.secrets.bulletin-privkey.path}
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
