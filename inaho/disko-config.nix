{
  fileSystems."/persist".neededForBoot = true;
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "513M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "defaults" ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings = {
                allowDiscards = true;
              };
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # /old_roots created by impermanence
                  "/persist" = {
                    mountpoint = "/persist";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "/swap" = {
                    mountpoint = "/.swapvol";
                    swap.swapfile.size = "32G";
                    # RAM is 16GB so at least twice that for RAM swap
                    # Want to use hibernate so +16GB
                    # Total 32GB
                  };
                };
              };
            };
          };
        };
      };
    };
    disk.extra = {
      type = "disk";
      device = "/dev/nvme0n1";
      content.type = "gpt";
      content.partitions.luks2 = {
        size = "100%";
        content = {
          type = "luks";
          name = "crypted2";
          passwordFile = "/tmp/secret.key";
          settings.allowDiscards = true;
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ];
            subvolumes = {
              "/backups".mountpoint = "/backups";
              "/backups".mountOptions = [
                "compress=zstd"
                "noatime"
              ];
              "/inaba".mountpoint = "/inaba";
              "/inaba".mountOptions = [
                "compress=zstd"
                "noatime"
              ];
              "/GF-01".mountpoint = "/GF-01";
              "/GF-01".mountOptions = [
                "compress=zstd"
                "noatime"
              ];
            };
          };
        };
      };
    };
  };
}
