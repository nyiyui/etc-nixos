{
  config,
  lib,
  pkgs,
  nixpak,
  ...
}:

let
  mkNixPak = nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  keepassxc-sandboxed = mkNixPak {
    config =
      { sloth, ... }:
      {
        app.package = pkgs.keepassxc;

        flatpak.appId = "org.keepassxc.keepassxc";

        bubblewrap = {
          sockets = {
            wayland = true;
          };
          dieWithParent = true;
          bind.ro = [ "/etc/fonts" ];
          bind.dev = [ "/dev/dri" ];
        };

        app.binPath = "bin/keepassxc";
      };
  };
in
{
  environment.systemPackages = [ keepassxc-sandboxed.config.env ];
}
