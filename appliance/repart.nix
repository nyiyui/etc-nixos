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
      default = "4G"; # ~8-10% according to Arch Wiki, so use image-size/8 for ez
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
    boot.uki.name = "assr-appliance-uki";
    boot.initrd.systemd.repart.enable = true;
    # TODO: how to boot.initrd.systemd.repart.empty?

    # fileSystems."/" =
    #   let
    #     repartConfig = config.image.repart.partitions.root.repartConfig;
    #   in
    #   {
    #     device = "/dev/disk/by-partlabel/${repartConfig.Label}";
    #     fsType = repartConfig.Format;
    #   };

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
          repartConfig = {
            Type = "root"; # IDK if it's possible to have verity of non-root, so just make this "root" for now
            Label = "root_${config.system.image.version}";
            SizeMinBytes = config.assr.appliance.image-size;
            SizeMaxBytes = config.assr.appliance.image-size;
            Format = "erofs";
            Verity = "data";
            VerityMatchKey = "root";
            SplitName = "root";
          };
        };
        root-verity.repartConfig = {
          Type = "root-verity";
          Label = "root-verity_${config.system.image.version}";
          SizeMinBytes = config.assr.appliance.verity-hash-size;
          SizeMaxBytes = config.assr.appliance.verity-hash-size;
          Verity = "hash";
          VerityMatchKey = "root";
          SplitName = "root-verity";
        };

        empty-root.repartConfig = {
          Type = "root";
          SizeMinBytes = config.assr.appliance.image-size;
          SizeMaxBytes = config.assr.appliance.image-size;
          SplitName = "-";
        };
        empty-root-verity.repartConfig = {
          Type = "root-verity";
          SizeMinBytes = config.assr.appliance.verity-hash-size;
          SizeMaxBytes = config.assr.appliance.verity-hash-size;
          SplitName = "-";
        };
      };
    };
    # TODO: ↓ set /etc/repart.d since we are bootstrapping from a non-image
    systemd.repart = {
      enable = true;
      partitions = {
        root = {
            Type = "root"; # IDK if it's possible to have verity of non-root, so just make this "root" for now
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
      };
    };
  };
}
