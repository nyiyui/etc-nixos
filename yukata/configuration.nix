{
  specialArgs,
  config,
  lib,
  pkgs,
  home-manager,
  nixos-hardware,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    home-manager.nixosModule
    ../base.nix
    ../headless.nix
    ../thunderbolt.nix
    ../autoUpgrade-https.nix
    ../home-manager.nix
  ];

  networking.hostName = "yukata";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-3fd3cf43-8dcb-4744-8f21-f504aa4a300e".device =
    "/dev/disk/by-uuid/3fd3cf43-8dcb-4744-8f21-f504aa4a300e";

  networking.networkmanager.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
