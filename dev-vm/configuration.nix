{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}:

{
  imports = [
    specialArgs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disko-config.nix
    ../base.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  networking.hostName = "dev-vm";

  services.qemuGuest.enable = true;
  services.openssh.enable = true;

  system.stateVersion = "24.11"; # Set to current or expected stateVersion
}