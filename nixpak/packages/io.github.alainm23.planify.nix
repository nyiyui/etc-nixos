{
  config,
  lib,
  pkgs,
  nixpak,
  nixpkgs-unstable,
  system,
  ...
}:

let
  mkNixPak = nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  planify = nixpkgs-unstable.legacyPackages.${system}.planify;

  sandboxed = mkNixPak {
    config =
      { sloth, ... }:
      {
        imports = [
          ../modules/xdg-home.nix
          (import ../modules/flatpak.nix { appId = "io.github.alainm23.planify"; })
          ../modules/gui-base.nix
          ../modules/network.nix
        ];
        app.package = planify;

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
