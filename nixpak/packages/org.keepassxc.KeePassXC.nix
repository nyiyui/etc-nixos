{
  config,
  lib,
  pkgs,
  nixpak,
  ...
}:

# TODO: portal doesn't work

let
  mkNixPak = nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  sandboxed = mkNixPak {
    config =
      { sloth, ... }:
      {
        imports = with nixpak.nixpakModules; [
          gui-base
        ];
        app.package = pkgs.keepassxc;

        flatpak.appId = "org.keepassxc.keepassxc";
        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        bubblewrap = {
          network = false;
          dieWithParent = true;
          bind.rw = [
            (sloth.concat' sloth.runtimeDir "/doc")
            "${config.services.syncthing.settings.folders.geofront.path}"
          ];
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
