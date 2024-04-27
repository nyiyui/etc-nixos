{ config, pkgs, ... }:
let
  hostName = config.networking.hostName;
  resticPassword = "backup-ssd/restic-password-${hostName}";
  sshKey = "backup-ssd/ssh-key-${hostName}.id_ed25519";
  sshHost = "mizunami@asuna.umi";
  repository = "sftp:${sshHost}:/mnt/mizunami/backup-01";
  knownHosts = ''
asuna.umi ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2bzRLCipVbL7IC6w8XzTAmE/odyMJEKd7JDdC7wZ1op01AAADnk2343n09wsny7ICq2aCKJigx00yR5mA/tMVuaO0vckz20gZrsjcBVWcNPRa0yb3b+YdtF3LFojtR8AqVD7GhHJnLWVxEj+F2pM++d+HF4LdBbkiVdrrYqiHBHPIaq22jR+bWZPp6K5BM+gHh/q6Kc3S2Cdu3SPqW0RN0FoeUwOBSkueldLTv6jE+aZFzWq+AjprmgY1YmO6pGr06/qG2LvAS1LSUk00HaH6vQiCnPI/HGieWitF/7zftiGoYjLxvklazeQQQimpKk5MVGZrbmox56dawGMoe2v40yo9Gh9HSQgjTbCxWHpfZOoY4VH6+clMvhblrryybrfML21ZuDQ/NBzs5+CTelK5bfRv7fCWWZ4miSnqHnZ2t31WeUk521EjaKwtE3dynwy4cCAgP0S8zuzBnsa+oFHU26L8lQY5+xwMhasV7qTGYZ1NiNA7wh2A4ajzMXDG+ms=
asuna.umi ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGlUCBBk9TQgT8P9Ube4aALUR3vjeyuRyFCvFnVyqqcIQG7jt5YSiivqSGi9w4nAe49D7CCvU20aPml4AnGma0M=
asuna.umi ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMp/4oh3cwQO0bYoKUH6lYHZtzto4eFHQIpwXBSt7e4h
'';
in {
  # TODO: port is open (not secure!)
  systemd.timers.backup-restic = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = "true";
      RandomizedDelaySec = "30m";
      AccuracySec = "30m";
    };
  };
  systemd.services.backup-restic = let
    asUser = "${pkgs.doas}/bin/doas -u nyiyui";
    password = "$(cat ${config.age.secrets.${resticPassword}.path})";
  in {
    script = let
      sftpCommand = ''${pkgs.openssh}/bin/ssh ${sshHost} -o IdentitiesOnly=yes -i ${config.age.secrets.${sshKey}.path} -o UserKnownHostsFile=${pkgs.writeText "backup-restic-ssd-known-hosts" knownHosts} -s sftp'';
    in ''
      set -eu
      export RESTIC_REPOSITORY="${repository}"
      export RESTIC_PASSWORD="${password}"
      export HOME="${config.users.users.nyiyui.home}"
      ${pkgs.restic}/bin/restic backup --tag ${hostName},systemd "$HOME" -o sftp.command='${sftpCommand}'
    '';
    unitConfig.StartLimitIntervalSec = 300;
    unitConfig.StartLimitBurst = 5;
    serviceConfig.Nice = 19;
    serviceConfig.Restart = "on-failure";
    serviceConfig.RestartSec = 30;
    wantedBy = [ "default.target" ];
  };
  age.secrets.${resticPassword} = {
    file = ./secrets + "/${resticPassword}.age";
    owner = "root";
    group = "root";
    mode = "400";
  };
  age.secrets.${sshKey} = {
    file = ./secrets + "/${sshKey}.age";
    owner = "root";
    group = "root";
    mode = "400";
  };
}
