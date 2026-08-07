{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.assr.wlsunset;
in
{
  options.assr.wlsunset = {
    enable = lib.mkEnableOption "gammastep with geoclue2 support";
    temperature = {
      day = lib.mkOption {
        type = lib.types.int;
        default = 6500;
        description = "Daytime temperature";
      };
      night = lib.mkOption {
        type = lib.types.int;
        default = 2000;
        description = "Nighttime temperature";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.geoclue2.enable = true;

    environment.systemPackages = [
      (pkgs.writeShellScriptBin "sunrise" ''
        systemctl --user stop gammastep-geoclue
      '')
      (pkgs.writeShellScriptBin "sunset" ''
        systemctl --user restart gammastep-geoclue
      '')
    ];

    systemd.user.services.gammastep-geoclue = {
      description = "gammastep with geoclue2 location updates";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.gammastep}/bin/gammastep -m wayland -l geoclue2 -t ${toString cfg.temperature.day}:${toString cfg.temperature.night}";
        Restart = "always";
      };
    };
  };
}
