# https://github.com/A1ca7raz/nurpkgs/blob/0636255a9b67e86618a29737c2dc0304fbb5326e/pkgs/_nixpaks/_modules/desktop.nix
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
          ../modules/xdg-home2.nix
          (import ../modules/flatpak.nix { appId = "org.chromium.Chromium"; })
          ../modules/gui-base.nix
          ../modules/network.nix
        ];
        app.package = pkgs.chromium;

        dbus.policies = {
          "org.mpris.MediaPlayer2.firefox.*" = "own";
          "org.freedesktop.NetworkManager" = "talk";
        };

        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        bubblewrap = {
          dieWithParent = true;
          env.NIXOS_OZONE_WL = "1";
          bind.ro = [
            [
              (sloth.concat' sloth.appCacheDir "/nixpak-app-shared-tmp")
              "/tmp"
            ] # maybe needed idk
            # TODO: remove /tmp bind once we know this isn't needed
          ];
        };
      };
  };
in

{
  environment.systemPackages = [ sandboxed.config.env ];
}
