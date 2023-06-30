{ config, ... }:
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "cirno.nyiyui.ca" = {
        locations."/".proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
      };
    };
  };
  services.nix-serve = {
    enable = true;
    secretKeyFile = config.age.secrets."cirno-nix-serve-priv-key.pem".path;
  };
  age.secrets."cirno-nix-serve-priv-key.pem" = {
    file = ../secrets/cirno-nix-serve-priv-key.pem.age;
    owner = "nix-serve";
    group = "nix-serve";
    mode = "400";
  };
}
