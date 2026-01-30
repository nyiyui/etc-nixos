# https://github.com/A1ca7raz/nurpkgs/blob/0636255a9b67e86618a29737c2dc0304fbb5326e/pkgs/_nixpaks/_modules/desktop.nix
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
          ++ [ ../modules/xdg-home.nix ../modules/tz.nix (import ../modules/flatpak.nix { appId = "org.mozilla.firefox"; }) ../modules/xdg-portal.nix ];
        app.package = pkgs.firefox;

        dbus = {
          enable = true;
          policies = {
            "org.mozilla.firefox.*" = "own";
            "org.mozilla.firefox_beta.*" = "own";
            "org.mpris.MediaPlayer2.firefox.*" = "own";
            "org.freedesktop.NetworkManager" = "talk";
          };
        };

        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        etc.sslCertificates.enable = true;

        bubblewrap = {
          network = true;
          sockets.pulse = true;
          dieWithParent = true;
          bind.rw = [
            (sloth.concat' sloth.homeDir "/.mozilla") # TODO: figure out how to put this under .var/nixpak-app
          ];
          bind.ro = [
            [
              "${pkgs.firefox}/lib/firefox"
              "/app/etc/firefox"
            ]
            "/run/opengl-driver/lib"
          ];
          bind.dev = [ "/dev/shm" "/dev/dri" ];
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
