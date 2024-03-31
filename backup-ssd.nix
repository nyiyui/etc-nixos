{ config, pkgs, ... }:
let
  hostName = config.networking.hostName;
  resticPassword = "${hostName}.backup-restic-password";
  repository = "/mnt/backup/restic-backup";
in {
  # TODO: port is open (not secure!)
  systemd.timers.backup-restic-ssd = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = "true";
      RandomizedDelaySec = "30m";
      AccuracySec = "30m";
    };
  };
  fileSystems.${repository} = {
    device = "/dev/disk/by-partuuid/702ddf9a-82df-47b1-88f6-4ce3b73d4ddc";
    options = [
      "x-systemd.automount"
    ];
  };
  systemd.services.backup-restic-ssd = let
    asUser = "${pkgs.doas}/bin/doas -u nyiyui";
    password = "$(cat ${config.age.secrets.${resticPassword}.path})";
    inherit repository;
  in {
    wants = [ "backup-rclone-serve.service" ];
    after = [ "backup-rclone-serve.service" ];
    script = ''
      set -eu
      export RESTIC_REPOSITORY="${repository}"
      export RESTIC_PASSWORD="${password}"
      export HOME="${config.users.users.nyiyui.home}"
      ${pkgs.su}/bin/su --preserve-environment -- nyiyui ${pkgs.restic}/bin/restic backup --tag ${hostName},systemd -e /home/nyiyui/mcpt-backup-2023-07-08/all ${config.users.users.nyiyui.home}
    '';
    unitConfig.StartLimitIntervalSec = 300;
    unitConfig.StartLimitBurst = 5;
    serviceConfig.Nice = 19;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 30;
    wantedBy = [ "default.target" ];
  };
  age.secrets.${resticPassword} = {
    file = ./secrets/backup-restic-password.age;
    owner = "root";
    group = "root";
    mode = "400";
  };
}
