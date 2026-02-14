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
        imports = [
          ../modules/xdg-home.nix
          (import ../modules/flatpak.nix { appId = "org.mozilla.firefox"; })
          ../modules/gui-base.nix
          ../modules/network.nix
        ];
        app.package = pkgs.firefox;

        dbus.policies = {
          "org.mpris.MediaPlayer2.firefox.*" = "own";
          "org.freedesktop.NetworkManager" = "talk";
        };

        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        bubblewrap = {
          dieWithParent = true;
          bind.rw = [
            (sloth.concat' sloth.homeDir "/.mozilla") # TODO: figure out how to put this under .var/nixpak-app
          ];
          bind.ro = [
            [
              "${pkgs.firefox}/lib/firefox"
              "/app/etc/firefox"
            ]
          ];
          bind.dev = [
            "/dev/shm"
          ];
        };
      };
  };
in
{
  environment.systemPackages = [ sandboxed.config.env ];
}
