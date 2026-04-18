{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.assr.services.backup-persist-push;
  backupPersistLib = import ./lib.nix { inherit lib; };
  inherit (backupPersistLib) backupPersistHostKeyPath;
  isBackupPersistPushStorageDevice = config.networking.hostName == cfg.storageDevice;
  isBackupPersistPushBackedUpDevice = builtins.elem config.networking.hostName cfg.backedUpDevices;
in
{
  imports = [
    ./storage.nix
    ./push.nix
  ];

  options.assr.services.backup-persist-push = {
    enable = lib.mkEnableOption "push /persist backup snapshots to a storage device";
    storageDevice = lib.mkOption {
      type = lib.types.str;
      description = "Hostname of the storage device receiving pushed /persist backups.";
    };
    backedUpDevices = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "Hostnames of devices that push /persist backups to the storage device.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(builtins.elem cfg.storageDevice cfg.backedUpDevices);
        message = "assr.services.backup-persist-push: storageDevice must not be in backedUpDevices";
      }
      {
        assertion = !(isBackupPersistPushStorageDevice && isBackupPersistPushBackedUpDevice);
        message = "assr.services.backup-persist-push: a host cannot be both storage and backed-up";
      }
      {
        assertion = builtins.pathExists (backupPersistHostKeyPath cfg.storageDevice);
        message = "assr.services.backup-persist-push: unknown storageDevice `${cfg.storageDevice}`";
      }
      {
        assertion = builtins.all (
          backupPersistBackedUpDevice:
          builtins.pathExists (backupPersistHostKeyPath backupPersistBackedUpDevice)
        ) cfg.backedUpDevices;
        message = "assr.services.backup-persist-push: backedUpDevices contains unknown host(s)";
      }
    ];

    users.groups.backup-persist = lib.mkIf (
      isBackupPersistPushStorageDevice || isBackupPersistPushBackedUpDevice
    ) { };
    users.users.backup-persist =
      lib.mkIf (isBackupPersistPushStorageDevice || isBackupPersistPushBackedUpDevice)
        {
          isSystemUser = true;
          group = "backup-persist";
          shell = pkgs.dash;
        };
  };
}
