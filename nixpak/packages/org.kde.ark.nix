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
          (import ../modules/flatpak.nix { appId = "org.mozilla.firefox"; })
          ../modules/gui-base.nix
          ../modules/network.nix
        ];
        app.package = pkgs.kdePackages.ark;

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
