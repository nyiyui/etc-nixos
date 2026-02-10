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
      rec {
        imports =
          with nixpak.nixpakModules;
          [
            gui-base
          ]
          ++ [
            ../modules/xdg-home.nix
            ../modules/tz.nix
          ];
        app.package = pkgs.signal-desktop;

        flatpak.appId = "org.signal.Signal";
        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        etc.sslCertificates.enable = true;

        dbus = {
          enable = true;
        };

        bubblewrap = {
          network = true;
          dieWithParent = true;
          env.GTK_USE_PORTAL = "1";
          # Make xdg-desktop-portal treat this as a sandboxed app and export picked files via document-portal.
          env.FLATPAK_ID = flatpak.appId;
          env.NIXOS_OZONE_WL = "1";
          bind.rw = [
            (sloth.concat' sloth.runtimeDir "/doc")
          ];
          bind.ro = [
            "/etc/machine-id"
          ];
          bind.dev = [ "/dev/shm" ];
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
