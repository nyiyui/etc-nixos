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
        imports =
          with nixpak.nixpakModules;
          [
            gui-base
          ]
          ++ [ ../modules/xdg-home.nix ];
        app.package = pkgs.firefox;

        dbus.policies = {
          "org.mozilla.firefox.*" = "own";
          "org.mozilla.firefox_beta.*" = "own";
          "org.mpris.MediaPlayer2.firefox.*" = "own";
          "org.freedesktop.NetworkManager" = "talk";
        };

        flatpak.appId = "org.mozilla.firefox";
        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        etc.sslCertificates.enable = true;

        bubblewrap = {
          network = true;
          sockets.pipewire = true;
          dieWithParent = true;
          bind.rw = [
            (sloth.concat' sloth.runtimeDir "/doc")
            (sloth.concat' sloth.homeDir "/.mozilla") # TODO: figure out how to put this under .var/nixpak-app
          ];
          bind.ro = [
            [
              "${pkgs.firefox}/lib/firefox"
              "/app/etc/firefox"
            ]
            "/etc/machine-id"
          ];
          bind.dev = [ "/dev/shm" ];
        };
      };
  };
in
{
  environment.systemPackages = [ keepassxc-sandboxed.config.env ];
}
