{ config, pkgs, lib, specialArgs, ... }:
{
  programs.niri.config = builtins.readFile ./config.kdl;

  programs.waybar.settings.mainBar = {
    modules-center = [ "wlr/taskbar" ];

    "wlr/taskbar" = {
      format = "{icon} {app_id} {title}";
      icon = true;
    };
  };
}
