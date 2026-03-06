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
        app.package = pkgs.helix;
        flatpak.appId = "ca.kiyuri.editor-sandbox";

        gpu.enable = false;
        locale.enable = true;
        dbus.enable = false;

        bubblewrap = {
          network = true;
          dieWithParent = true;
          env = {
            HELIX_DISABLE_CLIPBOARD = "1";
          };
          bind.ro = [
            (sloth.concat' sloth.homeDir "/.config/helix")
            "/etc/machine-id"
            "/etc/resolv.conf"
          ];
          bind.rw = [
            "."
            "/tmp"
            sloth.runtimeDir
            [ sloth.xdgCacheHome (sloth.mkdir sloth.appCacheDir) ]
          ];
          bind.dev = [
            "/dev/tty"
            "/dev/shm"
            "/dev/console"
          ];
        };
      };
  };
in
{
  imports = [ ../../home-manager.nix ];

  config = lib.mkIf config.assr.editor-sandbox.enable {
    environment.systemPackages = [ sandboxed.config.env ];
    environment.variables.editor = lib.mkOverride 900 "hx";
    kiyurica.home-manager.enable = true;
    home-manager.users.kiyurica =
      { ... }:
      {
        programs.helix = {
          package = sandboxed.config.env;
          themes = {
            "kawamo_to_seseragi" = ./kawamo_to_seseragi.toml;
          };
          enable = true;
          defaultEditor = true;
          settings = {
            theme = "kawamo_to_seseragi";
            editor.line-number = "relative";
          };
        };
      };
  };
}
