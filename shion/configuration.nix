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
    ../sound.nix
    ../thunderbolt.nix
    ../tpm.nix
    ../autoUpgrade-https.nix
    ../sway.nix
    ../home-manager.nix
    ../syncthing.nix
    ../secureboot.nix
    ../power.nix
  ];

  networking.hostName = "shion";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-3fd3cf43-8dcb-4744-8f21-f504aa4a300e".device =
    "/dev/disk/by-uuid/3fd3cf43-8dcb-4744-8f21-f504aa4a300e";

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

  nyiyui.desktop.sway.enable = true;
  services.xserver.enable = true;
  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.gtk = {
      enable = true;
      extraConfig = ''
        keyboard=onboard
      '';
    };
  };
  environment.systemPackages = [ pkgs.onboard ];

  home-manager.users.nyiyui =
    { lib, ... }:
    {
      home.file."${config.services.syncthing.settings.folders.inaba.path}/.stignore".text = lib.mkForce ''
        .direnv
        /hisame
        /geofront
        !/2025
        !/seekback
        !/music-library
        /**
      '';

      # borders needed for dragging on touchscreen
      nyiyui.sway.noBorder = false;
      wayland.windowManager.sway.config.window.titlebar = true;
      nyiyui.graphical.onScreenKeyboard.enable = true;
    };
}
