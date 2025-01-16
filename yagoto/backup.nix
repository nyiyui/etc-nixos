{ config, pkgs, ... }:
{
  age.secrets.restic-password = {
    file = ../secrets/yagoto-restic-password.txt.age;
    owner = "root";
    mode = "400";
  };

  systemd.timers.backup-restic = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = "true";
    };
  };
  systemd.services.backup-restic = {
    script = ''
      set -eu
      export RESTIC_REPOSITORY='rest:https://irinaka.nyiyui.ca:53955/yagoto/main'
      export RESTIC_REST_USERNAME=yagoto
      export RESTIC_REST_PASSWORD="$(cat ${config.age.secrets.restic-password.path})"
      export RESTIC_PASSWORD_FILE=${config.age.secrets.restic-password.path}
      ${pkgs.restic}/bin/restic backup --tag systemd /var/lib
    '';
    unitConfig.StartLimitIntervalSec = 300;
    unitConfig.StartLimitBurst = 5;
    serviceConfig.Nice = 19;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 30;
    wantedBy = [ "default.target" ];
  };
}
