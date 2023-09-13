{ config, lib, pkgs, home-manager, nixos-hardware, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    home-manager.nixosModule
    { }
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen
    ../common.nix
    ../tlp.nix
    ../sound.nix
    ../thunderbolt.nix
  ];

  networking.hostName = "minato";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";

  i18n.defaultLocale = "ja_JP.UTF-8";

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  services.openssh.enable = true;

  # Brightness adjust
  programs.light.enable = true;

  programs.sway.enable = true;
  xdg.portal.wlr.enable = true;
  services.xserver.enable = true;

  services.xserver.displayManager = {
    lightdm = { enable = true; };
    autoLogin = {
      enable = true;
      user = "nyiyui";
    };
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  miyamizu.services.target.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
