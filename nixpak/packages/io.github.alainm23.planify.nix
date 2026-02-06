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
          with nixpak.nixpakModules;
          [
            gui-base
          ]
          ++ [
            ../modules/xdg-home.nix
            ../modules/tz.nix
            (import ../modules/flatpak.nix { appId = "io.github.alainm23.planify"; })
            ../modules/xdg-portal.nix
          ];
        app.package = pkgs.planify;

        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        etc.sslCertificates.enable = true;

        bubblewrap = {
          network = true;
          dieWithParent = true;
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
