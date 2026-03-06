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
        app.package = pkgs.dash;
        flatpak.appId = "ca.kiyuri.dash-sandbox";

        gpu.enable = false;
        locale.enable = true;
        dbus.enable = false;

        bubblewrap = {
          dieWithParent = true;
          bind.rw = [
            "."
          ];
          bind.dev = [
            "/dev/tty"
          ];
        };
      };
  };
in
{
  config = lib.mkIf config.assr.editor-sandbox.enable {
    environment.systemPackages = [ sandboxed.config.env ];
  };
}
