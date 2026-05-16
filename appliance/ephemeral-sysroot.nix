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
  config.boot.initrd.systend.storePaths = with pkgs; [ cryptsetup e2fsprogs coreutils ];
  config.boot.initrd.systemd.services.ephemeral-sysroot = {
    description = "format ephemeral sysroot for this boot";
    wantedBy = [ "initrd.target" ];
    before = [ "sysroot.mount" ];
    serviceConfig.Type = "oneshot";
    bindsTo = [ "dev-disk-by\\x2dpartlabel-ephemeral\\x2dsysroot.device" ];
    after   = [ "dev-disk-by\\x2dpartlabel-ephemeral\\x2dsysroot.device" ];
    environment.PART = "/dev/disk/by-partlabel/${partlabel}";
    enableStrictShellChecks = true;
    script = ''
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
