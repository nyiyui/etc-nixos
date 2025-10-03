{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.kiyurica.desktop.niri.enable && config.kiyurica.desktop.niri.enableUWSM) {
    home-manager.users.kiyurica = {
      imports = [
        {
          programs.niri.settings = {
            spawn-at-startup = [
              {
                argv = [
                  "uwsm"
                  "finalize"
                ];
              }
            ];
            binds = {
              "Mod+Return".action.spawn = [
                "uwsm-app"
                "--"
                "foot"
              ];
              "Mod+D".action.spawn = [
                "fuzzel"
                "--launch-prefix=uwsm-app --"
              ];
              "Mod+Shift+Return".action.spawn = [
                "uwsm-app"
                "--"
                "firefox"
              ];
              "Mod+Alt+Shift+Return".action.spawn = [
                "uwsm-app"
                "--"
                "chromium"
              ];
              "Mod+Alt+Return".action.spawn = [
                "uwsm-app"
                "--"
                "rnote"
              ];
              "Mod+Alt+L".action.spawn = [ "swaylock" ];
            };
          };
        }
      ];
    };

    programs.uwsm = {
      enable = true;
      waylandCompositors.niri = {
        # becomes niri-uwsm.desktop
        binPath = "/run/current-system/sw/bin/niri-session";
        prettyName = "Niri";
        comment = "Niri-based session managed by UWSM";
      };
    };
  };
}
