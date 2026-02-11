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
        imports = [
          ../modules/xdg-home.nix
          ../modules/tz.nix
          (import ../modules/flatpak.nix { appId = "org.mozilla.Thunderbird"; })
          ../modules/xdg-portal.nix
          ../modules/gui-base.nix
          ../modules/network.nix
        ];
        app.package = pkgs.thunderbird;

        dbus = {
          enable = true;
          policies = {
            "org.mozilla.thunderbird.*" = "own";
            "org.freedesktop.NetworkManager" = "talk";
          };
        };

        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        bubblewrap = {
          dieWithParent = true;
          bind.rw = [
            (sloth.concat' sloth.homeDir "/.thunderbird") # TODO: figure out how to put this under .var/nixpak-app
          ];
          bind.dev = [ "/dev/shm" ];
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
