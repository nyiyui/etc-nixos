{ nixpkgs, config, lib, pkgs, ... }:
# modified from https://gitlab.com/hunorg/nixos-rpi-headless
{
  imports =
    [
      "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      ./hardware-configuration.nix
      ../base.nix
      ../autoUpgrade-git.nix
    ];
  # 
  # Raspberry Pi 4 firmware
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];
  hardware.bluetooth.enable = false;

  # Bootloader
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Quiet boot
  boot.consoleLogLevel = 0;
  boot.kernelParams = [ "quiet" "loglevel=0" ];

  # WiFi driver fixes for Pi 4
  # NOTE: Not sure if using Wi-Fi (currently wired Eth)
  # Change regulatory domain to your country: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2
  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom=US
    options brcmfmac roamoff=1 feature_disable=0x82000
  '';

  # Networking
  networking.hostName = "currant";
  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
  };

  # Unblock WiFi at boot (common Pi issue)
  systemd.services.rfkill-unblock-wifi = {
    description = "Unblock WiFi";
    wantedBy = [ "multi-user.target" ];
    before = [ "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock wifi";
      RemainAfterExit = true;
    };
  };

  # mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish.enable = true;
    publish.addresses = true;
  };

  # Tailscale VPN - access Pi from anywhere
  services.tailscale.enable = true;

  # SSH
  services.openssh = {
    enable = true;
  };
  systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];

  # Users
  users.users.root.initialPassword = "nixos";

  # SD image
  sdImage.compressImage = false;
  system.stateVersion = "25.11";
}

