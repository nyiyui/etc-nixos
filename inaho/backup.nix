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
      ${pkgs.restic}/bin/restic backup --tag systemd /inaba /GF-01 /persist /backups/vps-7de6b7ba /backups/caldav
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

  age.secrets.backup-vps-7de6b7ba = {
    file = ./backup-vps-7de6b7ba.id_ed25519.age;
    owner = "root";
    mode = "400";
  };

  systemd.timers.backup-vps-7de6b7ba = {
    # NOTE: backup-vps-7de6b7ba.service may run after backup-restic.service started, so the worst latency will be 48 hours for a backup, which isn't…horrible
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = "true";
    };
  };
  systemd.services.backup-vps-7de6b7ba = {
    path = [
      pkgs.rsync
      pkgs.openssh
    ];
    script = ''
      rsync -avzc -e "ssh -o StrictHostKeyChecking=no -i $CREDENTIALS_DIRECTORY/backup-vps-7de6b7ba" backup-access@vps-7de6b7ba.tailcbbed9.ts.net:/var/lib/convind4 /backups/vps-7de6b7ba
    '';
    unitConfig.StartLimitIntervalSec = 300;
    unitConfig.StartLimitBurst = 5;
    serviceConfig = {
      Nice = 19;
      Restart = "on-failure";
      RestartSec = 120;
      LoadCredential = "backup-vps-7de6b7ba:${config.age.secrets.backup-vps-7de6b7ba.path}";
      PrivateTmp = true;
      RemoveIPC = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
    };
  };

  assr.services.backup-caldav = {
    enable = true;
    url = "https://cdav.migadu.com/principals/ken.shibata@kiyuri.ca";
    usernameFile = pkgs.writeText "username" "ken.shibata@kiyuri.ca";
    passwordFile = ./caldav-password.cred;
    destination = "/backups/caldav";
  };
}
