{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.assr.services.backup-persist-push;
  backupPersistLib = import ./lib.nix { inherit lib; };
  inherit (backupPersistLib) getBackupPersistHostKey;
  backupPersistKnownHosts = pkgs.writeText "backup-persist-push-known-hosts" "${cfg.storageDevice}.tailcbbed9.ts.net ${getBackupPersistHostKey cfg.storageDevice}";
  backupPersistSshOptions = "-o ConnectTimeout=30 -o ConnectionAttempts=1 -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${backupPersistKnownHosts} -i $CREDENTIALS_DIRECTORY/backup-persist-push_id_ed25519";
in
{
  config = lib.mkIf (cfg.enable && builtins.elem config.networking.hostName cfg.backedUpDevices) {
    systemd.timers.backup-persist-push = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = "true";
      };
    };

    systemd.services.backup-persist-push = {
      wants = [
        "network-online.target"
        "tailscaled.service"
      ];
      after = [
        "network-online.target"
        "tailscaled.service"
      ];
      path = [
        pkgs.openssh
        pkgs.rsync
      ];
      script = ''
        set -eu
        rsync -a --delete --no-owner --no-group --no-devices --no-specials -e "ssh ${backupPersistSshOptions}" --exclude 'home/kiyurica/inaba/' /persist/ backup-persist@${cfg.storageDevice}.tailcbbed9.ts.net:
      '';
      unitConfig.StartLimitIntervalSec = 300;
      unitConfig.StartLimitBurst = 5;
      serviceConfig = {
        Type = "oneshot";
        User = "backup-persist";
        Group = "backup-persist";
        Nice = 19;
        Restart = "on-failure";
        RestartSec = 120;
        # Use a dedicated SSH client key for backup-persist rather than reusing
        # the machine's SSH host identity key.
        LoadCredentialEncrypted = "backup-persist-push_id_ed25519:${../${config.networking.hostName}/backup-persist-push_id_ed25519}";
        AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];
        CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" ];
        ReadOnlyPaths = [ "/persist" ];
        PrivateTmp = true;
        RemoveIPC = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
      };
    };
  };
}
