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
        dependencies =
          { nixpakModules }:
          with nixpakModules;
          [
            gui-base
          ];
        app.package = pkgs.keepassxc;

        flatpak.appId = "org.keepassxc.keepassxc";

        bubblewrap = {
          network = false;
          dieWithParent = true;
        };

        app.binPath = "bin/keepassxc";
      };
  };
in
{
  environment.systemPackages = [ keepassxc-sandboxed.config.env ];
}
