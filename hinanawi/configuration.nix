{ config, lib, pkgs, home-manager, nixos-hardware, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    home-manager.nixosModule
    { }
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen
    ../common.nix
    ../syncthing.nix
    ../power.nix
    ../fprint.nix
    ../sound.nix
    ../vlc.nix
    ../kuromiya.nix
    ../miyamizu.nix
    ../docker.nix
    ../thunderbolt.nix
    ../restic.nix
    ../backup.nix
    ../tpm.nix
    ../dns.nix
    ../wine.nix
    ../hisame.nix
  ];

  networking.hostName = "hinanawi";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Setup keyfile
  boot.initrd.secrets = { "/crypto_keyfile.bin" = null; };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-cfc0ad37-5315-44c7-ade3-24ebde45b146".device =
    "/dev/disk/by-uuid/cfc0ad37-5315-44c7-ade3-24ebde45b146";
  boot.initrd.luks.devices."luks-cfc0ad37-5315-44c7-ade3-24ebde45b146".keyFile =
    "/crypto_keyfile.bin";

  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "ja_JP.UTF-8";

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  #services.getty.autologinUser = "nyiyui";
  # TODO: remove when gui etc works

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

  reimu.enable = true;
  reimu.address = "10.42.0.6/32";
  reimu.udp2raw.enable = true;

  miyamizu.services.target.enable = true;

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
    };
  };
}
