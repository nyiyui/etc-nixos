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
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen
    ../common.nix
    ../syncthing.nix
    ../power.nix
    ../fprint.nix
    ../sound.nix
    ../vlc.nix
    ../qrystal2.nix
    ../docker.nix
    ../multipass.nix
    ../thunderbolt.nix
    ../restic.nix
    ../backup.nix
    ../tpm.nix
    ../adb.nix
    ../hisame.nix
    #../niri.nix
    ../sway.nix
    ../autoUpgrade-https.nix
  ];

  networking.hostName = "hinanawi";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-cfc0ad37-5315-44c7-ade3-24ebde45b146".device = "/dev/disk/by-uuid/cfc0ad37-5315-44c7-ade3-24ebde45b146";
  boot.initrd.luks.devices."luks-cfc0ad37-5315-44c7-ade3-24ebde45b146".keyFile = "/crypto_keyfile.bin";

  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "ja_JP.UTF-8";

  #services.getty.autologinUser = "nyiyui";
  # TODO: remove when gui etc works

  # Brightness adjust
  programs.light.enable = true;

  xdg.portal.wlr.enable = true;

  #hardware.opengl = {
  #  enable = true;
  #  extraPackages = with pkgs; [
  #    onevpl-intel-gpu # move to vpl-gpu-rt on NixOS >24.05
  #    intel-media-driver
  #    intel-vaapi-driver
  #  ];
  #};

  reimu.enable = true;
  reimu.address = "10.42.0.6/32";

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

  hisame.services.sync = {
    enable = true;
    path = "/home/nyiyui/inaba/hisame";
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
      nyiyui.qrystal2 = true;
      nyiyui.hasBacklight = true;
      nyiyui.nixosUpgrade = true;
    };

  networking.wireguard.interfaces = {
    roji = {
      ips = [ "10.9.0.1/32" ];
      privateKeyFile = config.age.secrets.roji-privkey.path;
      peers = [
        {
          publicKey = "JFqCTZZkVfZnd+OD5Fq57NUXcngsfoNAuqXdaGHvpyw=";
          allowedIPs = [ "10.9.0.2/32" ];
          endpoint = "128.61.106.120:60409";
          persistentKeepalive = 30;
        }
      ];
    };
  };

  age.secrets.roji-privkey = {
    file = ../secrets/roji-hinanawi.privkey.age;
    owner = "nyiyui";
    group = "nyiyui";
    mode = "400";
  };
}
