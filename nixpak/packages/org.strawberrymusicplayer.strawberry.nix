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
      {
        imports =
          [
            ../modules/gui-base.nix
            ../modules/xdg-home.nix
            ../modules/tz.nix
            (import ../modules/flatpak.nix { appId = "org.strawberrymusicplayer.strawberry"; })
          ];
        app.package = pkgs.strawberry;
        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        dbus.enable = true;

        bubblewrap = {
          dieWithParent = true;
          bind.rw = [ "/tmp" ];
          bind.dev = [
            "/dev/shm"
          ];
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
