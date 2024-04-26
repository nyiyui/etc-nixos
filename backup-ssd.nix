{ config, pkgs, ... }:
let
  hostName = config.networking.hostName;
  resticPassword = "backup-ssd/restic-password-${hostName}";
  sshKey = "backup-ssd/ssh-key-${hostName}.id_ed25519";
  repository = "sftp:mizunami@asuna.umi:/mnt/mizunami/restic-repo";
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
  systemd.services.backup-restic-ssd = let
    asUser = "${pkgs.doas}/bin/doas -u nyiyui";
    password = "$(cat ${config.age.secrets.${resticPassword}.path})";
  in {
    wants = [ "backup-rclone-serve.service" ];
    after = [ "backup-rclone-serve.service" ];
    script = ''
      set -eu
      export RESTIC_REPOSITORY="${repository}"
      export RESTIC_PASSWORD="${password}"
      export HOME="${config.users.users.nyiyui.home}"
      ${pkgs.restic}/bin/restic backup --tag ${hostName},systemd "$HOME"
    '';
    unitConfig.StartLimitIntervalSec = 300;
    unitConfig.StartLimitBurst = 5;
    serviceConfig.Nice = 19;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 30;
    wantedBy = [ "default.target" ];
  };
  age.secrets.${resticPassword} = {
    file = ./secrets + "${resticPassword}.age";
    owner = "root";
    group = "root";
    mode = "400";
  };
  age.secrets.${sshKey} = {
    file = ./secrets + "${sshKey}.age";
    owner = "root";
    group = "root";
    mode = "400";
  };
}
