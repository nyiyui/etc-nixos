{ pkgs, ... }:
let
  theme = ./kawamo_to_seseragi.toml;
  config = pkgs.writeText "helix-config.toml" ''
    theme = "kawamo_to_seseragi"

    [editor]
    line-number = "relative"

    [editor.soft-wrap]
    enable = true
  '';
in
{
  environment.systemPackages = [ pkgs.helix ];

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  systemd.tmpfiles.rules = [
    "L /home/kiyurica/.config/helix/config.toml - - - - ${config}"
    "L /home/kiyurica/.config/helix/themes/kawamo_to_seseragi.toml - - - - ${theme}"
  ];
}
