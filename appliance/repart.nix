{
  config,
  lib,
  pkgs,
  modulesPath,
  self,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) efiArch;
  efiArchUppercased = lib.toUpper efiArch;
in
{
  imports = [
    (modulesPath + "/image/repart.nix")
  ];

  options.assr.appliance = {
    image-size = lib.mkOption {
      type = lib.types.str;
      description = "size of partition containing nix store";
      default = "32G";
    };
    verity-hash-size = lib.mkOption {
      type = lib.types.str;
      description = "size of verity has partition of nix store";
      default = "4G"; # ~8-10% according to Arch Wiki, so use image-size/8 for simplicity
    };
  };

  config = {
    system.image.version =
      let
        revCount = toString (self.revCount or 0);
        shortRev = self.shortRev or "dirty";
      in
      "${revCount}.${shortRev}";
    system.image.id = "assr-appliance";
    system.nixos.label = "assr_${config.system.image.version}";
    boot.uki.name = "assr-appliance-uki";
    boot.uki.version = config.system.image.version; # controls boot entry name??? idk
    boot.initrd.systemd.repart.enable = false; # default, but here for clarity; see next line
    # On suzaku, during stage 1, systemd-repart probably triggers partprobe which probably kills systemd-veritysetup. Since repartitioning isn't required for boot, move this to stage 2.

    nix.enable = false;
    system.switch.enable = false;
    users.mutableUsers = false;

    fileSystems = {
      "/nix/store" =
        let
          repartConfig = config.image.repart.partitions.root.repartConfig;
        in
        {
          device = "/dev/mapper/root"; # dm-verity has name "root" since that's the repart config we use
          fsType = repartConfig.Format;
        };
    };

    # image.repart is only reflected in the built systemd image
    image.repart = {
      name = config.system.image.id;
      split = true;
      partitions = {
        esp = {
          contents = {
            "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
              "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
            "/EFI/Linux/${config.system.boot.loader.ukiFile}".source =
              "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
          };
          repartConfig = {
            Format = "vfat";
            Label = "boot";
            SizeMinBytes = "200M";
            Type = "esp";
          };
        };
        root = {
          storePaths = [ config.system.build.toplevel ];
          nixStorePrefix = "/";
          repartConfig = {
            Type = "root"; # not "root" per se but other options don't exactly match what we're doing here either
            Label = "root_${config.system.image.version}";
            SizeMinBytes = config.assr.appliance.image-size;
            SizeMaxBytes = config.assr.appliance.image-size;
            Format = "erofs";
            Verity = "data";
            VerityMatchKey = "root";
            SplitName = "root.%U"; # the partuuid of root and root-verity need to be specific for verity to work
          };
        };
        root-verity.repartConfig = {
          Type = "root-verity";
          Label = "root-verity_${config.system.image.version}";
          SizeMinBytes = config.assr.appliance.verity-hash-size;
          SizeMaxBytes = config.assr.appliance.verity-hash-size;
          Verity = "hash";
          VerityMatchKey = "root";
          SplitName = "root-verity.%U";
        };

        empty-root.repartConfig = {
          Type = "root";
          Label = "root_0.0empty";
          SizeMinBytes = config.assr.appliance.image-size;
          SizeMaxBytes = config.assr.appliance.image-size;
          SplitName = "-";
        };
        empty-root-verity.repartConfig = {
          Type = "root-verity";
          Label = "root-verity_0.0empty";
          SizeMinBytes = config.assr.appliance.verity-hash-size;
          SizeMaxBytes = config.assr.appliance.verity-hash-size;
          SplitName = "-";
        };
      };
    };
    systemd.repart = {
      enable = true;
      partitions = {
        root = {
          Type = "root";
          Label = "root_${config.system.image.version}";
          SizeMinBytes = config.assr.appliance.image-size;
          SizeMaxBytes = config.assr.appliance.image-size;
          Format = "erofs";
        };
        root-verity = {
          Type = "root-verity";
          Label = "root-verity_${config.system.image.version}";
          SizeMinBytes = config.assr.appliance.verity-hash-size;
          SizeMaxBytes = config.assr.appliance.verity-hash-size;
        };

        empty-root = {
          Type = "root";
          SizeMinBytes = config.assr.appliance.image-size;
          SizeMaxBytes = config.assr.appliance.image-size;
        };
        empty-root-verity = {
          Type = "root-verity";
          SizeMinBytes = config.assr.appliance.verity-hash-size;
          SizeMaxBytes = config.assr.appliance.verity-hash-size;
        };

        ephemeral-sysroot = {
          Type = "linux-generic";
          Label = "ephemeral-sysroot";
          SizeMinBytes = config.assr.appliance.ephemeral-sysroot-size;
          SizeMaxBytes = config.assr.appliance.ephemeral-sysroot-size;
        };
      };
    };
  };
}
