{
  fileSystems."/var".neededForBoot = true;
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };

            userdata = {
              size = "1536G";
              content = {
                type = "luks";
                name = "userdata";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/home/kiyurica/inaba" = {
                      mountpoint = "/home/kiyurica/inaba";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "/home/kiyurica/.local/share/fish" = {
                      mountpoint = "/home/kiyurica/.local/share/fish";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                  };
                };
              };
            };
            sysdata = {
              size = "32G";
              content = {
                type = "luks";
                name = "sysdata";
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes."/var" = {
                    mountpoint = "/var";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
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
