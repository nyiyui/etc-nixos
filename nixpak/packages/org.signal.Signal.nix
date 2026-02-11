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
          ../modules/tz.nix
          ../modules/gui-base.nix
          (import ../modules/flatpak.nix { appId = "org.signal.Signal"; })
          ../modules/xdg-portal.nix
          ../modules/network.nix
        ];
        app.package = pkgs.signal-desktop;

        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        bubblewrap = {
          dieWithParent = true;
          env.NIXOS_OZONE_WL = "1";
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
