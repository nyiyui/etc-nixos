{
  nixpkgs,
  config,
  lib,
  pkgs,
  ...
}:
# modified from https://gitlab.com/hunorg/nixos-rpi-headless
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    ./hardware-configuration.nix
    ./home-assistant.nix
    ../base.nix
    ../autoUpgrade-git.nix
  ];

  # Raspberry Pi 4 firmware
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Bootloader
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Quiet boot
  boot.consoleLogLevel = 0;
  boot.kernelParams = [
    "quiet"
    "loglevel=0"
  ];

  # WiFi driver fixes for Pi 4
  # NOTE: Not using Wi-Fi
  # Change regulatory domain to your country: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=US
    options brcmfmac roamoff=1 feature_disable=0x82000
  '';

  # Networking
  networking.hostName = "currant";
  networking.useNetworkd = true;

  # If using Wi-Fi, below is common RasPi workaround for Wi-Fi:
  # # Unblock WiFi at boot (common Pi issue)
  # systemd.services.rfkill-unblock-wifi = {
  #   description = "Unblock WiFi";
  #   wantedBy = [ "multi-user.target" ];
  #   before = [ "systemd-networkd.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.util-linux}/bin/rfkill unblock wifi";
  #     RemainAfterExit = true;
  #   };
  # };

  # mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.addresses = true;
  };

  services.resolved.enable = true;

  kiyurica.tailscale.enable = true;
  services.tailscale.extraUpFlags = [ "--advertise-exit-node" ];

  environment.systemPackages = [
    (pkgs.writeShellScriptBin "wake-minamo" ''
      exec ${pkgs.wol}/bin/wol 00:d8:61:c9:b6:f0
    '')
  ];

  autoUpgrade.directFlake = true;

  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

  # SD image
  sdImage.compressImage = false;
  system.stateVersion = "25.11";
}
