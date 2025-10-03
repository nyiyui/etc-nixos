{
  config,
  lib,
  pkgs,
  ...
}:
{
  config =
    lib.mkIf (config.kiyurica.desktop.niri.enable && !config.kiyurica.desktop.niri.enableUWSM)
      {
        home-manager.users.kiyurica = {
          imports = [
            {
              programs.niri.settings.binds = with config.lib.niri.actions; {
                "Mod+Alt+L".action.spawn = [ "swaylock" ];
                "Mod+Shift+Return".action.spawn = [ "firefox" ];
                "Mod+Alt+Shift+Return".action.spawn = [ "chromium" ];
                "Mod+Return".action.spawn = [ "footclient" ];
                "Mod+Alt+Return".action.spawn = [
                  "${pkgs.rnote}/bin/rnote"
                ];
              };
            }
          ];
        };
      };
}
