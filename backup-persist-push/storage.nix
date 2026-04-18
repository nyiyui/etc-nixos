{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.assr.services.backup-persist-push;
  backupPersistLib = import ./lib.nix { inherit lib; };
  inherit (backupPersistLib) getBackupPersistClientKey;

  mkRestrictedBackupCommand =
    backupPersistBackedUpDevice:
    let
      backupDir = "/backups/persists/${backupPersistBackedUpDevice}";
    in
    pkgs.writeShellScript "backup-persist-push-${backupPersistBackedUpDevice}" ''
      set -eu
      mkdir -p ${lib.escapeShellArg backupDir}
      # rrsync -wo restricts this key to write-only sync access under backupDir.
      exec ${pkgs.rrsync}/bin/rrsync -wo ${lib.escapeShellArg backupDir}
    '';
in
{
  config = lib.mkIf (cfg.enable && config.networking.hostName == cfg.storageDevice) {
    users.users.backup-persist.openssh.authorizedKeys.keys = map (
      backupPersistBackedUpDevice:
      ''from="100.64.0.0/10",restrict,command="${mkRestrictedBackupCommand backupPersistBackedUpDevice}" ${getBackupPersistClientKey backupPersistBackedUpDevice}''
    ) cfg.backedUpDevices;

    systemd.tmpfiles.rules = [
      "d /backups/persists 0750 backup-persist backup-persist -"
    ]
    ++ map (
      backupPersistBackedUpDevice:
      "d /backups/persists/${backupPersistBackedUpDevice} 0750 backup-persist backup-persist -"
    ) cfg.backedUpDevices;
  };
}
