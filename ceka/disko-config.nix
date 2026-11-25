let
  # userdata is unlocked on first login and not automatically unlocked on boot.
  # cf. ceka/pin-unlock/default.nix
  userdataMountOptions = [ "noauto" ];
in
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
              # use non-default 8300 type to make sure this is not mistaken for ephemeral-sysroot.
              type = "8309";
              content = {
                type = "luks";
                name = "userdata";
                # Unlocked in stage 2, by the first login of the boot
                initrdUnlock = false;
                settings.allowDiscards = true;
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/var/lib/dev-vm" = {
                      mountpoint = "/var/lib/dev-vm";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ]
                      ++ userdataMountOptions;
                    };
                    "/home/kiyurica/inaba" = {
                      mountpoint = "/home/kiyurica/inaba";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ]
                      ++ userdataMountOptions;
                    };
                    "/home/kiyurica/GF-01" = {
                      mountpoint = "/home/kiyurica/GF-01";
                      mountOptions = [
                        "compress=zstd"
                      ]
                      ++ userdataMountOptions;
                    };
                    "/home/kiyurica/.local/share/fish" = {
                      mountpoint = "/home/kiyurica/.local/share/fish";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ]
                      ++ userdataMountOptions;
                    };
                    "/home/kiyurica/.config/syncthing" = {
                      mountpoint = "/home/kiyurica/.config/syncthing";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ]
                      ++ userdataMountOptions;
                    };
                    "/home/kiyurica/.var" = {
                      mountpoint = "/home/kiyurica/.var";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ]
                      ++ userdataMountOptions;
                    };
                    "/home/kiyurica/.mozilla" = {
                      mountpoint = "/home/kiyurica/.mozilla";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ]
                      ++ userdataMountOptions;
                    };
                  };
                };
              };
            };
            sysdata = {
              size = "32G";
              # use non-default 8300 type to make sure this is not mistaken for ephemeral-sysroot.
              type = "8309";
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
