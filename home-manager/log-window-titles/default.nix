{
  config,
  pkgs,
  lib,
  specialArgs,
  ...
}:
{
  options.kiyurica.services.log-window-titles.enable =
    lib.mkEnableOption "log window titles using sway-ipc(7)";

  config = lib.mkIf config.kiyurica.services.log-window-titles.enable {
    systemd.user.services.log-window-titles = {
      Unit = {
        Description = "log window titles using sway-ipc(7)";
        StartLimitIntervalSec = 350;
        StartLimitBurst = 30;
      };
      Service = {
        ExecStart = pkgs.writeShellScript "start-window-title-tracker.sh" ''
          export DB_PATH="$XDG_DATA_HOME/window-title-tracker.sqlite3"
          export PATH="$PATH:${pkgs.sqlite}/bin:${pkgs.jq}/bin"
          sh ${./main.sh}
        '';
        Restart = "on-failure";
        RestartSec = 3;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
