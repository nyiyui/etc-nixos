{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [ ../../home-manager.nix ];

  config = lib.mkIf config.assr.editor-sandbox.enable {
    environment.systemPackages = [ pkgs.helix ];
    environment.variables.editor = lib.mkOverride 900 "hx";
    kiyurica.home-manager.enable = true;
    home-manager.users.kiyurica =
      { ... }:
      {
        programs.helix = {
          package = sandboxed-hx;
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
