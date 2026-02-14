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
        imports = [ ../modules/gui-base.nix ];
        app = {
          package = pkgs.libreoffice;
          binPath = "bin/libreoffice";
          # extraEntrypoints = [ # TODO: fix
          #   "bin/sbase"
          #   "bin/scalc"
          #   "bin/sdraw"
          #   "bin/simpress"
          #   "bin/smath"
          #   "bin/soffice"
          #   "bin/swriter"
          #   # "bin/unopkg"
          # ];
        };

        flatpak.appId = "org.libreoffice.LibreOffice";
        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        bubblewrap = {
          network = false;
          dieWithParent = true;
          bind.rw = [ (sloth.concat' sloth.runtimeDir "/doc") ];
          bind.ro = [ "/etc/machine-id" ];
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
