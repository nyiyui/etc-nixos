{ config, pkgs, ... }:
{
  age.secrets.restic-password = {
    file = ../secrets/inaho-restic-password.txt.age;
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
      export RESTIC_REPOSITORY='/backups/restic-repo'
      export RESTIC_PASSWORD_FILE=$CREDENTIALS_DIRECTORY/restic-password
      ${pkgs.restic}/bin/restic backup --tag systemd /inaba /GF-01 /persist
    '';
    unitConfig.StartLimitIntervalSec = 300;
    unitConfig.StartLimitBurst = 5;
    serviceConfig = {
      Nice = 19;
      Restart = "on-failure";
      RestartSec = 120;
      LoadCredential = "restic-password:${config.age.secrets.restic-password.path}";
      PrivateTmp = true;
      RemoveIPC = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      CapabilityBoundingSet = [ ];
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      PrivateNetwork = true;
    };
    wantedBy = [ "default.target" ];
  };
}
