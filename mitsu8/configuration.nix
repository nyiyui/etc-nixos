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
    { }
    ../base.nix
    ../i18n.nix
    ../reimu.nix
    ../doas.nix
    ../sound.nix
    ../sway.nix
    ../autoUpgrade-https.nix
    ../qrystal.nix
  ];

  networking.hostName = "mitsu8";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Enable networking
  networking.networkmanager.enable = true;

  powerManagement.cpuFreqGovernor = "performance";

  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  services.displayManager.autoLogin = {
    enable = true;
    user = "nyiyui";
  };

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_CA.UTF-8";
    LC_IDENTIFICATION = "en_CA.UTF-8";
    LC_MEASUREMENT = "en_CA.UTF-8";
    LC_MONETARY = "en_CA.UTF-8";
    LC_NAME = "en_CA.UTF-8";
    LC_NUMERIC = "en_CA.UTF-8";
    LC_PAPER = "en_CA.UTF-8";
    LC_TELEPHONE = "en_CA.UTF-8";
    LC_TIME = "en_CA.UTF-8";
  };

  services.libinput.enable = true;

  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  # Brightness adjust
  programs.light.enable = true;

  xdg.portal.wlr.enable = true;

  reimu.enable = true;
  reimu.address = "10.42.0.7/32";
  reimu.udp2raw.enable = false;

  home-manager.users.nyiyui = {
    services.wlsunset.temperature.night = 4000;
    wayland.windowManager.sway.config = {
      startup = [
        {
          command = "${pkgs.chromium}/bin/chromium '--proxy-server=socks5://10.42.0.1:1080' --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36'";
        }
      ];
      output = {
        "HDMI-A-1" = {
          mode = "3840x2160@60.000Hz";
          pos = "0 0";
          scale = "2";
        };
      };
    };
  };
}
