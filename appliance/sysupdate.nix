{
  config,
  pkgs,
  lib,
  ...
}:
{
  systemd.sysupdate = {
    enable = true;

    transfers = {
      "10-root-verity" = {
        Transfer = {
          ProtectVersion = "%A";
        };
        Source = {
          Type = "regular-file";
          Path = "/var/lib/updates/";
          MatchPattern = "${config.system.image.id}_@v.root-verity.@u.raw";
        };
        Target = {
          Type = "partition";
          Path = config.boot.initrd.systemd.repart.device;
          MatchPattern = "root-verity_@v";
          MatchPartitionType = "root-verity";
          PartitionFlags = "0";
          ReadOnly = "yes";
          InstancesMax = 2;
        };
      };
      "20-root" = {
        Transfer = {
          ProtectVersion = "%A";
        };
        Source = {
          Type = "regular-file";
          Path = "/var/lib/updates/";
          MatchPattern = "${config.system.image.id}_@v.root.@u.raw";
        };
        Target = {
          Type = "partition";
          Path = config.boot.initrd.systemd.repart.device;
          MatchPattern = "root_@v";
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
          Path = "/boot/EFI/Linux";
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

  # This is needed to auto-unlock LUKS with TPM 2 - https://discourse.nixos.org/t/full-disk-encryption-tpm2/29454/2
  boot.initrd.systemd.enable = true;
  boot.initrd.availableKernelModules = [
    "tpm_tis"
    "xhci_pci"
    "vmd"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];

  # Enable dm-verity in initrd
  boot.initrd.systemd.dmVerity.enable = true;
  boot.kernelParams = [
    "systemd.verity=1"
    "roothash=RoothashGoesHereRoothashGoesHereRoothashGoesHereRoothashGoesHere"
    # roothash= filled in after image build, see config.system.build.sysupdate-package
    "systemd.verity_root_options=restart-on-corruption"
    "rd.emergency=reboot"
    "rd.shell=0"
    "lockdown=confidentiality"
  ];

  system.build.sysupdate-package =
    let
      inherit (config.system) build;
      inherit (config.system.image) version id;
      ukiFile = config.system.boot.loader.ukiFile;
    in
    pkgs.runCommand "sysupdate-package-${config.system.image.version}"
      {
        nativeBuildInputs = [
          pkgs.jq
          pkgs.binutils
        ];
      }
      ''
        mkdir $out
        cp ${build.image}/${id}_${version}.root-verity.*.raw $out/
        cp ${build.image}/${id}_${version}.root.*.raw $out/

        # Extract roothash from repart-output.json
        roothash=$(jq -r '.[] | select(.label == "root-verity_${version}") | .roothash' ${build.image}/repart-output.json)

        echo "Injecting roothash $roothash into UKI"

        cp ${build.uki}/${ukiFile} $TMPDIR/${ukiFile}
        # Extract the existing command line and replace the placeholder roothash.
        # Replace instead of append (as prev. done), to avoid (potential) issues with imageBase
        objcopy --verbose --dump-section .cmdline=$TMPDIR/orig-cmdline.txt $TMPDIR/${ukiFile} $TMPDIR/objcopy-tmp

        sed "s/roothash=RoothashGoesHereRoothashGoesHereRoothashGoesHereRoothashGoesHere/roothash=$roothash/" $TMPDIR/orig-cmdline.txt > $TMPDIR/new-cmdline.txt
        echo -ne '\0' >> $TMPDIR/new-cmdline.txt

        objcopy --verbose --update-section .cmdline=$TMPDIR/new-cmdline.txt --set-section-flags .cmdline=contents,alloc,load,readonly,data $TMPDIR/${ukiFile} $out/${ukiFile}

        cd $out
        sha256sum * > SHA256SUMS
      '';
}
