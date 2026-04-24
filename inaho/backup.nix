{
  config,
  lib,
  pkgs,
  ...
}:
let
  backupPaths = [
    "/inaba"
    "/GF-01"
    "/persist"
    "/backups/persists"
    "/backups/vps-7de6b7ba"
    "/backups/caldav"
  ];
  backupPathsArgs = lib.escapeShellArgs backupPaths;
in
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
      export RESTIC_CACHE_DIR=$CACHE_DIRECTORY
      ${pkgs.restic}/bin/restic backup --tag systemd "''${backup_paths[@]}"
    '';
    unitConfig.StartLimitIntervalSec = 300;
    unitConfig.StartLimitBurst = 5;
    serviceConfig = {
      Nice = 19;
      Restart = "on-failure";
      RestartSec = 120;
      CacheDirectory = "restic";
      LoadCredential = "restic-password:${config.age.secrets.restic-password.path}";
      PrivateTmp = true;
      RemoveIPC = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      CapabilityBoundingSet = [ ];
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      # Intentionally keep backup-restic.service network-isolated to minimize
      # possible data exfiltration. Source hosts push their /persist backups.
      PrivateNetwork = true;
    };
    wantedBy = [ "default.target" ];
  };


  systemd.services.backup-restic-success-email = {
    script = ''
            set -eu
            export DOMAIN=kiyuri.ca
            export USER=script@$DOMAIN
            export TO=ken.shibata@$DOMAIN
            export SMTP_PASSWORD="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/script-email-password")"
            export LOG_TAIL="$(${pkgs.systemd}/bin/journalctl -u backup-restic.service -n 10 --no-pager -o short 2>/dev/null || true)"
            ${pkgs.swaks}/bin/swaks \
              --server smtp.migadu.com:587 \
              --tls \
              --auth LOGIN \
              --auth-user "$USER" \
              --auth-password "$SMTP_PASSWORD" \
              --from "$USER" \
              --to "$TO" \
              --header "Subject: backup-restic succeeded (on ${config.networking.hostName})" \
              --body "Completed at $(${pkgs.coreutils}/bin/date -Is).

      Recent backup-restic logs:
      $LOG_TAIL"
    '';
    serviceConfig = {
      Type = "oneshot";
      LoadCredentialEncrypted = [
        "script-email-password"
      ];
      PrivateTmp = true;
      RemoveIPC = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      ProtectClock = true;
      CapabilityBoundingSet = [ ];
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
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
