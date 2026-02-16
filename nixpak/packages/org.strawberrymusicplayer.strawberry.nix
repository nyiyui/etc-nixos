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
          ../modules/gui-base.nix
          ../modules/xdg-home.nix
          (import ../modules/flatpak.nix { appId = "org.strawberrymusicplayer.strawberry"; })
        ];
        app.package = pkgs.strawberry;
        fonts.fonts = config.fonts.packages; # https://github.com/nixpak/nixpak/issues/196

        dbus.enable = true;

        bubblewrap = {
          dieWithParent = true;
          bind.rw = [
            [
              (sloth.concat' sloth.appCacheDir "/nixpak-app-shared-tmp")
              "/tmp"
            ] # lock file /tmp/kdsingleapp-1000-strawberry.lock is necessary
            "${config.services.syncthing.settings.folders.inaba.path}/music-library" # don't use portals here since we want it to persist
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
