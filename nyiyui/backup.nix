{ ... }:
{
  programs.waybar.settings.mainBar = {
    modules-right = [ "custom/backup" ];
    "custom/backup" = {
      exec = script
      interval = 600;
    };
  };
}
