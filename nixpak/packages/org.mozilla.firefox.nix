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

  keepassxc-sandboxed = mkNixPak {
    config =
      { sloth, ... }:
      {
        imports = with nixpak.nixpakModules; [
          gui-base
        ] ++ [ ../modules/xdg-home.nix ];
        app.package = pkgs.firefox;

        flatpak.appId = "org.mozilla.firefox";
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
  environment.systemPackages = [ keepassxc-sandboxed.config.env ];
}

