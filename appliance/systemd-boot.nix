{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) efiArch;
  efiArchUppercased = lib.toUpper efiArch;
  systemdBootEfi = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";

  syncSystemdBoot = pkgs.writeShellApplication {
    name = "sync-appliance-systemd-boot";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
    ];
    text = ''
      set -eu
      export LC_ALL=C

      version="$(
        comm -12 \
          <(find /boot/EFI/systemd -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -u) \
          <(find /boot/EFI/BOOT -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -u) \
          | sort -V \
          | tail -n1
      )"

      [ -n "$version" ] || exit 0

      install -Dm0644 \
        "/boot/EFI/systemd/$version/systemd-boot${efiArch}.efi" \
        "/boot/EFI/systemd/systemd-boot${efiArch}.efi"
      install -Dm0644 \
        "/boot/EFI/BOOT/$version/BOOT${efiArchUppercased}.EFI" \
        "/boot/EFI/BOOT/BOOT${efiArchUppercased}.EFI"
    '';
  };
in
{
  assr.appliance.sysupdate.extraFiles = {
    "BOOT${efiArchUppercased}_${config.system.image.version}.EFI" = systemdBootEfi;
    "systemd-boot${efiArch}_${config.system.image.version}.efi" = systemdBootEfi;
  };

  systemd.sysupdate.transfers = {
    "05-systemd-boot" = {
      Transfer = {
        ProtectVersion = "%A";
      };
      Source = {
        Type = "regular-file";
        Path = "/var/lib/updates/";
        MatchPattern = "systemd-boot${efiArch}_@v.efi";
      };
      Target = {
        Type = "regular-file";
        Path = "/boot/EFI/systemd";
        MatchPattern = "@v/systemd-boot${efiArch}.efi";
        Mode = "0644";
        InstancesMax = 2;
      };
    };
    "06-systemd-boot-fallback" = {
      Transfer = {
        ProtectVersion = "%A";
      };
      Source = {
        Type = "regular-file";
        Path = "/var/lib/updates/";
        MatchPattern = "BOOT${efiArchUppercased}_@v.EFI";
      };
      Target = {
        Type = "regular-file";
        Path = "/boot/EFI/BOOT";
        MatchPattern = "@v/BOOT${efiArchUppercased}.EFI";
        Mode = "0644";
        InstancesMax = 2;
      };
    };
  };

  systemd.services.appliance-systemd-boot-sync = {
    description = "Sync the current systemd-boot EFI binaries";
    after = [ "boot.mount" ];
    requires = [ "boot.mount" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/boot";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${syncSystemdBoot}/bin/sync-appliance-systemd-boot";
    };
  };

  systemd.services.systemd-sysupdate.serviceConfig.ExecStartPost = [
    "${syncSystemdBoot}/bin/sync-appliance-systemd-boot"
  ];
}
