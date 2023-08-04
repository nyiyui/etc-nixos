{ config, ... }: {
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "cirno.msb.q.nyiyui.ca" = {
        locations."/".proxyPass =
          "http://${config.services.nix-serve.bindAddress}:${
            toString config.services.nix-serve.port
          }";
      };
    };
  };
  services.nix-serve = {
    enable = true;
    secretKeyFile = config.age.secrets."cirno-nix-serve-priv-key.pem".path;
  };
  age.secrets."cirno-nix-serve-priv-key.pem" = {
    file = ../secrets/cirno-nix-serve-priv-key.pem.age;
    group = "nix-serve";
    mode = "040";
  };
  networking.firewall.interfaces.msb.allowedTCPPorts =
    [ config.services.nix-serve.port ];
}
