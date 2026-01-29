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
        imports =
          with nixpak.nixpakModules;
          [
            gui-base
          ]
          ++ [ ../modules/xdg-home.nix ../modules/tz.nix ];
        app.package = pkgs.thunderbird;

        dbus.policies = {
          "org.freedesktop.NetworkManager" = "talk";
        };

        flatpak.appId = "org.mozilla.Thunderbird";
        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        etc.sslCertificates.enable = true;

        bubblewrap = {
          network = true;
          sockets.pipewire = true;
          dieWithParent = true;
          bind.rw = [
            (sloth.concat' sloth.runtimeDir "/doc")
            (sloth.concat' sloth.homeDir "/.thunderbird") # TODO: figure out how to put this under .var/nixpak-app
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
