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

    fileSystems."/nix/store" =
      let
        repartConfig = config.image.repart.partitions.nix-store.repartConfig;
      in
      {
        device = "/dev/disk/by-partlabel/${repartConfig.Label}";
        fsType = repartConfig.Format;
        neededForBoot = false; # TODO: temporary
        options = [ "nofail" ];
      };

    # Note: seems like image.repart also fills out /etc/repart.d in addition to image-building, contrary to https://github.com/applicative-systems/nixos-appliance-ota-update/blob/01ea6bc287189ccc477391e70812ca8a8c601046/system-configuration/image.nix#L37
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
        nix-store = {
          storePaths = [ config.system.build.toplevel ];
          nixStorePrefix = "/";
          repartConfig = {
            Type = "root"; # IDK if it's possible to have verity of non-root, so just make this "root" for now
            Label = "nix-store_${config.system.image.version}";
            SizeMinBytes = config.assr.appliance.image-size;
            SizeMaxBytes = config.assr.appliance.image-size;
            Format = "erofs";
            Verity = "data";
            VerityMatchKey = "nix-store";
            SplitName = "nix-store";
          };
        };
        nix-store-verity.repartConfig = {
          Type = "root-verity";
          Label = "nix-store-verity_${config.system.image.version}";
          SizeMinBytes = config.assr.appliance.verity-hash-size;
          SizeMaxBytes = config.assr.appliance.verity-hash-size;
          Verity = "hash";
          VerityMatchKey = "nix-store";
          SplitName = "nix-store-verity";
        };

        empty-nix-store.repartConfig = {
          Type = "root";
          SizeMinBytes = config.assr.appliance.image-size;
          SizeMaxBytes = config.assr.appliance.image-size;
          SplitName = "-";
        };
        empty-nix-store-verity.repartConfig = {
          Type = "root-verity";
          SizeMinBytes = config.assr.appliance.verity-hash-size;
          SizeMaxBytes = config.assr.appliance.verity-hash-size;
          SplitName = "-";
        };
        # TODO: root partition managed in suzaku/disko-config.nix for now
      };
    };
  };
}
