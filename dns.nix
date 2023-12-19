{ config, pkgs, ... }: let
  ula = "fda0:a4b2:2507::52";
in {
  services.unbound = {
    enable = true;
  };
  services.unbound.settings = {
    server.interface = [ "127.0.0.55" ula ];
    server.access-control = [ "127.0.0.55 allow" "${ula} allow" ];
  };
}
