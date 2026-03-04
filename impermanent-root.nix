{ lib, config, ... }:

with lib;

let
  cfg = config.impermanent-root;
in
{
  options.impermanent-root = {
    enable = mkEnableOption "impermanent root services";
    device = mkOption {
      type = types.str;
      default = "/dev/mapper/crypted";
      description = "Device to mount for btrfs operations.";
    };
    deleteOldRoots = {
      enable = mkEnableOption "delete old roots";
      days = mkOption {
        type = types.int;
        default = 30;
        description = "Delete roots older than this many days.";
      };
    };
  };

  config = mkIf cfg.enable {
    boot.initrd.systemd.services.swap-old-root = {
      description = "move old root to /old_roots and make new root at /root";
      wantedBy = [ "initrd.target" ];
      before = [ "sysroot.mount" ];
      serviceConfig.Type = "oneshot";
      enableStrictShellChecks = true;
      script = ''
        mkdir /btrfs_tmp
        mount ''${cfg.device} /btrfs_tmp
        if [[ -e /btrfs_tmp/root ]]; then
            mkdir -p /btrfs_tmp/old_roots
            timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
            mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
        fi

        btrfs subvolume create /btrfs_tmp/root
        umount /btrfs_tmp
      '';
    };

    systemd.services.delete-old-roots = mkIf cfg.deleteOldRoots.enable {
      description = "remove roots older than ''${toString cfg.deleteOldRoots.days} days";
      serviceConfig.Type = "oneshot";
      enableStrictShellChecks = true;
      script = ''
        mkdir /btrfs_tmp
        mount ''${cfg.device} /btrfs_tmp

        delete_subvolume_recursively() {
            IFS=$'\n'
            for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/btrfs_tmp/$i"
            done
            btrfs subvolume delete "$1"
        }

        for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +''${toString cfg.deleteOldRoots.days}); do
            if [ "$i" = "/btrfs_tmp/old_roots/" ]; then
                continue
            fi
            delete_subvolume_recursively "$i"
        done

        umount /btrfs_tmp
      '';
    };

    systemd.timers.delete-old-roots = mkIf cfg.deleteOldRoots.enable {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "15m";
        OnUnitActiveSec = "1d";
        Persistent = true;
      };
    };
  };
}
