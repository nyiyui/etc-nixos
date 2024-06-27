{
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    virtualHosts."kujo.hato.nyiyui.ca" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        root = "/var/kujo";
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 ];
}
