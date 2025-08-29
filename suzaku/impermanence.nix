{
  specialArgs,
  pkgs,
  lib,
  ...
}:
{
  imports = [ specialArgs.impermanence.nixosModules.impermanence ];
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib"
      "/etc/secureboot"
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
    ];
    files = [ "/etc/machine-id" ];
    users.kiyurica = {
      directories = [
        "inaba"
        "3d-spool"
        {
          directory = ".ssh";
          mode = "0700";
        }
        ".local/share/direnv"
        ".local/share/fish"
        ".local/share/nvim"
        ".local/share/log-window-titles"
        ".local/PrusaSlicer"
        ".local/share/prusa-slicer"
        ".mozilla/firefox"
        ".thunderbird"
        ".config/syncthing"
        ".config/sayonara"
      ];
    };
  };

  boot.initrd.systemd.services.swap-old-root = {
    description = "move old root to /old_roots and make new root at /root";
    wantedBy = [ "initrd.target" ];
    before = [ "sysroot.mount" ];
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir /btrfs_tmp
      mount /dev/mapper/crypted /btrfs_tmp
      if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$i"
      done

      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';
  };
}
