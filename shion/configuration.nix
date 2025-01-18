{
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
    ../common.nix
    ../power.nix
    ../fprint.nix
    ../sound.nix
    ../thunderbolt.nix
    ../tpm.nix
    ../sway.nix
    ../autoUpgrade-https.nix
  ];

  networking.hostName = "shion";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  i18n.defaultLocale = "ja_JP.UTF-8";

  programs.light.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    # https://bbs.archlinux.org/viewtopic.php?pid=1998573#p1998573
    General = {
      ControllerMode = "bredr";
      Experimental = true;
    };
  };

  services.xserver.enable = true;
  services.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = "nyiyui";
  };
  services.xserver.displayManager.lightdm = {
    enable = true;
  };
  security.polkit.enable = true;
  home-manager.users.nyiyui =
    { ... }:
    {
      nyiyui.hasBacklight = true;
      nyiyui.nixosUpgrade = true;
    };
}

