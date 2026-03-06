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
        flatpak.appId = "com.helix_editor.Helix";

        gpu.enable = false;
        locale.enable = true;
        dbus.enable = false;

        bubblewrap = {
          network = true;
          shareIpc = true;
          dieWithParent = true;

          bind.rw = [
            [ sloth.homeDir sloth.homeDir ]
            "/tmp"
          ];
          
          bind.ro = [
            "/etc"
            "/usr"
            "/bin"
          ];

          bind.dev = [ "/dev" ];

          env = {
            HELIX_RUNTIME = "${pkgs.helix}/lib/runtime";
            COLORTERM = "truecolor";
            HELIX_DISABLE_CLIPBOARD = "1";
            TERM = { key = "TERM"; type = "env"; };
          };
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
