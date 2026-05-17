{
  config,
  lib,
  pkgs,
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
                "foot"
              ];
              "Mod+D".action.spawn = [
                "fuzzel"
              ];
              "Mod+Shift+Return".action.spawn = [
                "firefox"
              ];
              "Mod+Alt+Return".action.spawn = [
                "${pkgs.gtk3}/bin/gtk-launch"
                "com.github.flxzt.rnote"
              ];
              "Mod+Alt+L".action.spawn = [
                "loginctl"
                "lock-session"
              ];
            };
          };
        }
      ];
    };

    programs.uwsm = {
      enable = true;
      waylandCompositors = { };
    };
    kiyurica.greeter.gtkgreet.compositor = [
      "/run/current-system/sw/bin/niri --session"
    ];
  };
}
