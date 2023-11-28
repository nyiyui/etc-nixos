{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../kuromiya.nix
    ../base.nix
    ../headless.nix
  ];

  # Bootloader.
  #boot.loader.grub = {
  #  enable = true;
  #  device = "/dev/sda";
  #  version = 2;
  #  efiSupport = true;
  #};
  boot.loader = {
    systemd-boot.enable = true;
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
  };

  networking.hostName = "kotiya"; # Define your hostname.

  networking.networkmanager.enable = true;
  i18n.defaultLocale = "en_CA.UTF-8";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  miyamizu.services.target.enable = true;
}
