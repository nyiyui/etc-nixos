{ config, lib, pkgs, specialArgs, home-manager, ... }:

{
  imports = [
    ./hardware-configuration.nix
    home-manager.nixosModule
    ../common.nix
    ../syncthing.nix
    ../power.nix
    ../sound.nix
    ../vlc.nix
    ../qrystal2.nix
    ../docker.nix
    ../wine.nix
    ../backup-ssd.nix
    ../sway.nix
    ../autoUpgrade-https.nix
  ];

  services.qrystal-device-client.config.Clients.irinaka.PrivateKeyPath = config.age.secrets."qrystal2-irinaka.wgprivkey".path;
  age.secrets."qrystal2-irinaka.wgprivkey" = {
    file = ../secrets/qrystal2-irinaka-${config.networking.hostName}.wgprivkey.age;
    owner = "qrystal-device";
    group = "qrystal-device";
    mode = "400";
  };

  networking.hostName = "chikusa";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "ja_JP.UTF-8";

  xdg.portal.wlr.enable = true;
  xdg.portal.config.common.default = "*";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

  # https://nixos.wiki/wiki/Nvidia
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true; # required
    open = false; # don't use open source kernel module ("alpha-quality/buggy")
    nvidiaSettings = true; # enable Nvidia settings menu
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  home-manager.users.nyiyui = {
    wayland.windowManager.sway.extraOptions = [ "--unsupported-gpu" ]; # welp
    nyiyui.nixosUpgrade = true;
  };
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  services.xserver.enable = true;
  services.xserver.displayManager = {
    autoLogin.enable = true;
    autoLogin.user = "nyiyui";
    lightdm = { enable = true; };
  };
  security.polkit.enable = true;
}
