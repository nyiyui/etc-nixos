{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = lib.mkIf (config.assr.desktop.niri.enable && config.assr.desktop.niri.enableUWSM) {
    hjem.users.kiyurica.rum.desktops.niri.spawn-at-startup = [
      [
        "uwsm"
        "finalize"
      ]
    ];

    programs.uwsm = {
      enable = true;
      waylandCompositors = { };
    };
    kiyurica.greeter.gtkgreet.compositor = [
      "/run/current-system/sw/bin/niri --session"
    ];

    # xdg-desktop-portal may start before uwsm patches the user environment
    # (systemctl show-environment) to include XDG_CURRENT_DESKTOP
    hjem.users.kiyurica.xdg.config.files."systemd/user/xdg-desktop-portal.service.d/after-uwsm-env.conf".text = ''
      [Unit]
      After=graphical-session-pre.target
    '';
  };
}
