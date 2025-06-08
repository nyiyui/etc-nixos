{
  fileSystems."/persist".neededForBoot = true;
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/ata-WDC_WD3200LPVX-22V0TT0_WD-WX81A14E9381";
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
                    # RAM is 8GB so at least twice that for RAM swap
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
  };
}
