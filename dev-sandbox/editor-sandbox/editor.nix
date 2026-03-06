{
  config,
  lib,
  pkgs,
  nixwrap,
  ...
}:

let
  wrap = nixwrap.packages.${pkgs.stdenv.hostPlatform.system}.wrap;
  sandboxed-hx = pkgs.writeShellScriptBin "hx" ''
    # -r for config
    # -n for network (LSPs often need it)
    exec ${wrap}/bin/wrap -n -r "$HOME/.config/helix" -- ${pkgs.helix}/bin/hx "$@"
  '';
in
{
  imports = [ ../../home-manager.nix ];

  config = lib.mkIf config.assr.editor-sandbox.enable {
    environment.systemPackages = [ sandboxed-hx ];
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
