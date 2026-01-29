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

  keepassxc-sandboxed = mkNixPak {
    config =
      { sloth, ... }:
      {
        imports =
          with nixpak.nixpakModules;
          [
            gui-base
          ]
          ++ [ ../modules/xdg-home.nix ../modules/tz.nix ];
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
          sockets.pulse = true;
          dieWithParent = true;
          env.GTK_USE_PORTAL = "1";
          # Make xdg-desktop-portal treat this as a sandboxed app and export picked files via document-portal.
          env.FLATPAK_ID = "org.mozilla.firefox";
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
            "/run/dbus/system_bus_socket"
          ];
          bind.dev = [ "/dev/shm" ];
        };
      };
  };
in
{
  environment.systemPackages = [ keepassxc-sandboxed.config.env ];
}
