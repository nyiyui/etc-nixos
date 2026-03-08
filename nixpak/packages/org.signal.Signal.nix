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

  sandboxed = mkNixPak {
    config =
      { sloth, ... }:
      rec {
        imports = [
          ../modules/xdg-home.nix
          ../modules/gui-base.nix
          (import ../modules/flatpak.nix { appId = "org.signal.Signal"; })
          ../modules/network.nix
        ];
        app.package = pkgs.signal-desktop;

        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        dbus.policies = {
          "org.freedesktop.ScreenSaver" = "talk";
        };

        bubblewrap = {
          dieWithParent = true;
          env = {
            NIXOS_OZONE_WL = "1";
          };
          bind.dev = [
            "/dev/shm"
          ];
          extraStorePaths = [ pkgs.xdg-utils ]; # xdg-settings
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
