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
  };
}
