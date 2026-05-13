{ config, pkgs, lib, ... }:
{
  systemd.sysupdate = {
    enable = true;

    transfers = {
      "10-nix-store-verity" = {
        Transfer = {
          ProtectVersion = "%A";
        };
        Source = {
          Type = "regular-file";
          Path = "/var/lib/updates/";
          MatchPattern = "${config.system.image.id}_@v.nix-store-verity.raw";
        };
        Target = {
          Type = "partition";
          Path = "auto"; # block device (e.g., NVMe drive) w/ root partition is selected, which may not work for all cases (e.g., root partition is tmpfs)
          MatchPattern = "nix-store_@v";
          MatchPartitionType = "root-verity";
          PartitionFlags = "0";
          ReadOnly = "yes";
          InstancesMax = 2;
        };
      };
      "20-nix-store" = {
        Transfer = {
          ProtectVersion = "%A";
        };
        Source = {
          Type = "regular-file";
          Path = "/var/lib/updates/";
          MatchPattern = "${config.system.image.id}_@v.nix-store.raw";
        };
        Target = {
          Type = "partition";
          Path = "auto";
          MatchPattern = "nix-store_@v";
          MatchPartitionType = "root";
          PartitionFlags = "0";
          ReadOnly = "yes";
          InstancesMax = 2;
        };
      };
      "30-uki" = {
        Transfer = {
          ProtectVersion = "%A";
        };
        Source = {
          Type = "regular-file";
          Path = "/var/lib/updates/";
          MatchPattern = "${config.boot.uki.name}_@v.efi";
        };
        Target = {
          Type = "regular-file";
          Path = "/EFI/Linux";
          MatchPattern = [
            "${config.boot.uki.name}_@v+@l-@d.efi"
            "${config.boot.uki.name}_@v+@l.efi"
            "${config.boot.uki.name}_@v.efi"
          ];
          Mode = "0644";
          TriesLeft = 3; # no particular reason why 3, but third time's the charm, right?
          TriesDone = 0;
          InstancesMax = 2;
        };
      };
    };
  };

  # Enable dm-verity in initrd
  boot.initrd.systemd.dmVerity.enable = true;

  system.build.sysupdate-package = let
    inherit (config.system) build;
    inherit (config.system.image) version id;
    in
    pkgs.runCommand "sysupdate-package-${config.system.image.version}" { }
      ''
        mkdir $out
        cp ${build.uki}/${config.system.boot.loader.ukiFile} $out/
        cp ${build.image}/${id}_${version}.nix-store-verity.raw $out/
        cp ${build.image}/${id}_${version}.nix-store.raw $out/
        cd $out
        sha256sum * > SHA256SUMS
      '';
}
