{
  config,
  lib,
  pkgs,
  ...
}:
let
  mapper = "crypt-ephemeral-sysroot";
  partlabel = "ephemeral-sysroot";
  script = pkgs.writeShellScript "ephemeral-sysroot.sh" ''
    echo "Generating ephemeral encryption key..."
    dd if=/dev/urandom of=/tmp/ephemeral.key bs=512 count=1 status=none

    echo "Formatting LUKS container..."
    cryptsetup luksFormat --type luks2 \
      --pbkdf pbkdf2 --pbkdf-force-iterations 1000 \
      --batch-mode --key-file /tmp/ephemeral.key "$PART"

    echo "Opening LUKS container..."
    cryptsetup open --key-file /tmp/ephemeral.key "$PART" ${lib.strings.escapeShellArg mapper}
    rm /tmp/ephemeral.key

    echo "Formatting inner volume as ext4..."
    mkfs.ext4 -F -q /dev/mapper/${lib.strings.escapeShellArg mapper}
  '';
in
{
  options.assr.appliance.ephemeral-sysroot-size = lib.mkOption {
    type = lib.types.str;
    description = "size of ephemeral root partition";
    default = "64G";
  };

  config.systemd.repart.partitions = {
    ephemeral-sysroot = {
      Type = "linux-generic";
      Label = partlabel;
      SizeMinBytes = config.assr.appliance.ephemeral-sysroot-size;
      SizeMaxBytes = config.assr.appliance.ephemeral-sysroot-size;
    };
  };
  config.boot.initrd.systemd.storePaths = with pkgs; [
    cryptsetup
    e2fsprogs
    coreutils
    script
  ];
  config.boot.initrd.systemd.services.ephemeral-sysroot = {
    description = "format ephemeral sysroot for this boot";
    wantedBy = [ "initrd.target" ];
    before = [ "sysroot.mount" ];
    path = with pkgs; [
      cryptsetup
      e2fsprogs
      coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${script}";
    };
    bindsTo = [ "dev-disk-by\\x2dpartlabel-ephemeral\\x2dsysroot.device" ];
    after = [ "dev-disk-by\\x2dpartlabel-ephemeral\\x2dsysroot.device" ];
    environment.PART = "/dev/disk/by-partlabel/${partlabel}";
    enableStrictShellChecks = true;
  };

  config.fileSystems."/" = {
    device = "/dev/mapper/${mapper}";
    fsType = "ext4";
  };
}
