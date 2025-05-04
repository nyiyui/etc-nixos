# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, specialArgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./disko-config.nix
      ./impermanence.nix
      ../secureboot.nix
      ../fprint.nix
      ../syncthing.nix
      ../thunderbolt.nix
      ../common.nix
      ../power.nix
      ../vlc.nix
      ../tpm.nix
      ../adb.nix
      ../sway.nix
      ../vnc.nix
      ../virt.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.kiyurica = {
    initialHashedPassword = "$y$j9T$g5xm0pLBFbK4W4c5BIENt/$D18bkwRRxH/MjSlInTZfvd2vE4Mxa.RQXARitTirV64";
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

  networking.hostName = "suzaku";

  nixpkgs.config.allowUnfree = true;

  services.udisks2.enable = true;

  kiyurica.desktop.sway.enable = true;
  kiyurica.greeter.gtkgreet.enable = true;
  home-manager.users.kiyurica =
    { ... }:
    {
      imports = [
        ../home-manager/activitywatch.nix
      ];
      kiyurica.hasBacklight = true;
      kiyurica.services.seekback.enable = true;
      # PAM requires fingerprint, so we can use touch to trigger PAM (instead of e.g. Enter key)
      programs.swaylock.settings.submit-on-touch = true;
    };

  kiyurica.networks.er605 = {
    enable = true;
    address = "10.9.0.97/32";
  };

  autoUpgrade.directFlake = true;
}
