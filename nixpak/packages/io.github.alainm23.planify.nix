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
          ];
        app.package = pkgs.planify;

        flatpak.appId = "io.github.alainm23.planify";
        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        etc.sslCertificates.enable = true;

        bubblewrap = {
          network = true;
          dieWithParent = true;
          bind.ro = [ "/etc/machine-id" ];
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
