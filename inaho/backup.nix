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
      set -euo pipefail
      export RESTIC_REPOSITORY='/backups/restic-repo'
      export RESTIC_PASSWORD_FILE=$CREDENTIALS_DIRECTORY/restic-password
      export RESTIC_CACHE_DIR=$CACHE_DIRECTORY
      export BACKUP_STATE_DIR=/var/lib/backup-restic
      export RUN_LOG="$BACKUP_STATE_DIR/runs.log"
      export TIMESTAMP="$(${pkgs.coreutils}/bin/date -Is)"
      export RESTIC_LOG="$(${pkgs.coreutils}/bin/mktemp)"
      export LOG_TAIL_LINES=20
      backup_paths=( ${backupPathsArgs} )

      latest_path_mod() {
        path="$1"
        latest="$(${pkgs.restic}/bin/restic ls --long --recursive --sort time latest "$path" 2>/dev/null | ${pkgs.coreutils}/bin/tail -n 1 || true)"
        if [ -z "$latest" ]; then
          echo "not found in latest snapshot or unreadable"
        else
          echo "$latest"
        fi
      }

      if ${pkgs.restic}/bin/restic backup --tag systemd "''${backup_paths[@]}" 2>&1 | ${pkgs.coreutils}/bin/tee "$RESTIC_LOG"; then
        result="success"
        status=0
      else
        status=$?
        result="failure (exit $status)"
      fi
      # Keep a concise excerpt in the digest.
      log_tail="$(${pkgs.coreutils}/bin/tail -n "''${LOG_TAIL_LINES}" "$RESTIC_LOG" || true)"

      {
        echo "=== $TIMESTAMP ==="
        echo "Result: $result"
        echo "Path last-modified:"
        for path in "''${backup_paths[@]}"; do
          echo "  $path: $(latest_path_mod "$path")"
        done
        echo
        echo "Restic log tail:"
        echo "$log_tail"
        echo
      } >> "$RUN_LOG"

      ${pkgs.coreutils}/bin/rm -f "$RESTIC_LOG"
      exit "$status"
    '';
    unitConfig.StartLimitIntervalSec = 300;
    unitConfig.StartLimitBurst = 5;
    serviceConfig = {
      Nice = 19;
      Restart = "on-failure";
      RestartSec = 120;
      CacheDirectory = "restic";
      StateDirectory = "backup-restic";
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

  systemd.timers.backup-restic-weekly-digest-email = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = "true";
    };
  };
  systemd.services.backup-restic-weekly-digest-email = {
    script = ''
      set -euo pipefail
      export DOMAIN=kiyuri.ca
      export USER=script@$DOMAIN
      export TO=ken.shibata@$DOMAIN
      export SMTP_PASSWORD="$(${pkgs.coreutils}/bin/cat "$CREDENTIALS_DIRECTORY/script-email-password")"
      export RUN_LOG=/var/lib/backup-restic/runs.log

      if [ -s "$RUN_LOG" ]; then
        digest="$(${pkgs.coreutils}/bin/cat "$RUN_LOG")"
      else
        digest="No backup-restic runs were recorded for this period."
      fi

      if ${pkgs.swaks}/bin/swaks \
        --server smtp.migadu.com:587 \
        --tls \
        --auth LOGIN \
        --auth-user "$USER" \
        --auth-password "$SMTP_PASSWORD" \
        --from "$USER" \
        --to "$TO" \
        --header "Subject: backup-restic weekly digest (on ${config.networking.hostName})" \
        --body "Generated at $(${pkgs.coreutils}/bin/date -Is).

Weekly backup-restic digest:
$digest"
      then

        # Clear the digest after it has been sent.
        ${pkgs.coreutils}/bin/truncate -s 0 "$RUN_LOG"
      fi
    '';
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "backup-restic";
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
