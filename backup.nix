{ config, pkgs, ... }: let
  port = 29679;
  hostName = config.networking.hostName;
  rcloneConf = "${hostName}.rclone.conf";
  resticPassword = "${hostName}.backup-restic-password";
in {
  # TODO: port is open (not secure!)
  systemd.timers.backup-restic = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1h";
      OnCalendar = "hourly";
      Persistent = "true";
      RandomizedDelaySec = "30m";
      AccuracySec = "30m";
    };
  };
  systemd.services.backup-restic = let
    asUser = "${pkgs.doas}/bin/doas -u nyiyui";
    password = "$(cat ${config.age.secrets.${resticPassword}.path})";
    repository = "rest:http://localhost:${toString port}";
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
  # TODO: rclone tries to save config for some reason
  #  1月 11 18:27:56 hinanawi backup-rclone-serve-start[2837]: ERROR : Failed to save config after 10 tries: failed to create temp file for new config: open /run/agenix/hinanawi.rclone.conf1784933065: permission denied
  systemd.services.backup-rclone-serve = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig.User = "backup-rclone";
    serviceConfig.Group = "backup-rclone";
    serviceConfig.Nice = 19;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 30;
    script = ''
      set -eu
      ${pkgs.rclone}/bin/rclone serve restic -v \
        --config ${config.age.secrets.${rcloneConf}.path} \
        --addr localhost:${toString port} \
        onedrive:restic-${hostName}
    '';
  };

  users.groups.backup-rclone = {};
  users.users.backup-rclone = {
    isNormalUser = true;
    description = "just for 'rclone serve restic'";
    group = "backup-rclone";
  };

  age.secrets.${rcloneConf} = {
    file = ./secrets/${hostName}.rclone.conf.age;
    owner = "backup-rclone";
    group = "backup-rclone";
    mode = "400";
  };
  age.secrets.${resticPassword} = {
    file = ./secrets/${hostName}.backup-restic-password.age;
    owner = "root";
    group = "root";
    mode = "400";
  };
}
