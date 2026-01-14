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

  keepassxc-sandboxed = mkNixPak {
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
          bind.rw = [ (sloth.concat' sloth.runtimeDir "/doc") ];
        };

        app.binPath = "bin/keepassxc";
      };
  };
in
{
  environment.systemPackages = [ keepassxc-sandboxed.config.env ];
}
