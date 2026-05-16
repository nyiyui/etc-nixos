{
  config,
  lib,
  pkgs,
  ...
}:
let
  mapper = "crypt-ephemeral-sysroot";
  partlabel = "ephemeral-sysroot";
in
{
  options.assr.appliance.ephemeral-sysroot-size = lib.mkOption {
    type = lib.types.str;
    description = "size of ephemeral root partition";
    default = "32G";
  };

  config.systemd.repart.partitions = {
    ephemeral-sysroot = {
      Type = "linux-generic";
      Label = partlabel;
      SizeMinBytes = config.assr.appliance.ephemeral-sysroot-size;
      SizeMaxBytes = config.assr.appliance.ephemeral-sysroot-size;
    };
  };
  config.boot.initrd.systemd.services.ephemeral-sysroot = {
    description = "format ephemeral sysroot for this boot";
    wantedBy = [ "initrd.target" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;

    path = with pkgs; [ cryptsetup e2fsprogs coreutils ];

    script = ''
      # Using partlabel instead of partuuid
      PART="/dev/disk/by-partlabel/"${lib.strings.escapeShellArg partlabel}

      echo "Waiting for root partition ${partlabel} to become available..."
      while [ ! -b "$PART" ]; do
        sleep 0.1
      done

      echo "Generating ephemeral encryption key..."
      dd if=/dev/urandom of=/tmp/ephemeral.key bs=512 count=1 status=none

      echo "Formatting LUKS container..."
      cryptsetup luksFormat --type luks2 \
        --pbkdf pbkdf2 --pbkdf-force-iterations 1000 \
        --batch-mode --key-file /tmp/ephemeral.key "$PART"

      echo "Opening LUKS container..."
      cryptsetup open --key-file /tmp/ephemeral.key "$PART" ${lib.strings.escapeShellArg mapper}

      echo "Formatting inner volume as ext4..."
      mkfs.ext4 -F -q /dev/mapper/${lib.strings.escapeShellArg mapper}

      # Securely wipe the ephemeral key from the initrd RAM
      rm /tmp/ephemeral.key
    '';
  };

  config.fileSystems."/" = {
    device = "/dev/mapper/${mapper}";
    fsType = "ext4";
  };
}
