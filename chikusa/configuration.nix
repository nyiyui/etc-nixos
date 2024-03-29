{ config, lib, pkgs, home-manager, nixos-hardware, ... }:

{
  imports = [
    ./hardware-configuration.nix
    home-manager.nixosModule
    ../common.nix
    ../syncthing.nix
    ../power.nix
    ../sound.nix
    ../vlc.nix
    ../kuromiya.nix
    ../miyamizu.nix
    ../docker.nix
    ../wine.nix
  ];

  networking.hostName = "chikusa";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "ja_JP.UTF-8";

  hardware.opengl.enable = true
  services.greetd = {
    enable = true;
    settings = rec {
      default_session = {
        command = "${pkgs.sway}/bin/sway";
        user = "nyiyui";
      };
    };
  };

  xdg.portal.wlr.enable = true;
  xdg.portal.config.common.default = "*";

  miyamizu.services.target.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    # https://bbs.archlinux.org/viewtopic.php?pid=1998573#p1998573
    General = { ControllerMode = "bredr"; };
  };
}

