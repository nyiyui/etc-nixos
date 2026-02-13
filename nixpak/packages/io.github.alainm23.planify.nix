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
          (import ../modules/flatpak.nix { appId = "io.github.alainm23.planify"; })
          ../modules/gui-base.nix
          ../modules/network.nix
        ];
        app.package = pkgs.planify;

        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        bubblewrap = {
          dieWithParent = true;
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
