# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  nixos-hardware,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.asus-zenbook-ux481-nvidia
    ../common.nix
    ../power-efficiency.nix
    ../sound.nix
    ../tpm.nix
    ../secureboot.nix
    #../virt.nix
    #../nixpak/packages/org.kde.ark.nix
    ../nixpak/packages/org.mozilla.firefox.nix
    # ../nixpak/packages/org.libreoffice.LibreOffice.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-c512f81b-1b63-4a84-b79d-15dbc2c97509".device =
    "/dev/disk/by-uuid/c512f81b-1b63-4a84-b79d-15dbc2c97509";
  networking.hostName = "thecutie"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,ua";
    variant = "";
    options = "grp:alt_shift_toggle";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.artems = {
    isNormalUser = true;
    description = "Artem Shelestov";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    telegram-desktop
    pkgs.wdisplays
  ];

  environment.shellAliases = {
    rebuild = "nix build ~/etc-nixos#nixosConfigurations.thecutie.config.system.build.toplevel --out-link result && doas nix-env -p /nix/var/nix/profiles/system --set ./result && doas ./result/bin/switch-to-configuration switch";
  };
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  kiyurica.desktop.niri = {
    enable = true;
    enableUWSM = true;
  };
  kiyurica.greeter.gtkgreet.enable = true;
  home-manager.users.artems =
    { pkgs, ... }:
    {
      kiyurica.hasBacklight = true;

      kiyurica.services.kanshi = {
        enable = true;
        builtinDisplay = "Chimei Innolux Corporation 0x14D5 Unknown";
      };
      services.kanshi.settings = [
        {
          output.criteria = "Chimei Innolux Corporation 0x14D5 Unknown";
          output.mode = "1920x1080@60.008Hz";
          output.scale = 1.0;
          output.adaptiveSync = true;
          output.position = "0,0";
        }
        {
          output.criteria = "BOE 0x087F Unknown";
          output.mode = "1920x1080@60.008Hz";
          output.scale = 1.0;
          output.adaptiveSync = true;
          output.position = "0,1080";
        }
      ];
      programs.niri.settings.input.keyboard.xkb = {
        layout = "us,ua";
        options = pkgs.lib.mkForce "grp:alt_shift_toggle";
      };
      kiyurica.icsUrlPath = config.age.secrets.icsUrlPath.path;
    };

  age.secrets.icsUrlPath = {
    file = ../secrets/ics-url-path.txt.age;
    owner = "artems";
    group = "artems";
    mode = "400";
  };

  autoUpgrade.directFlake = true;

  services.automatic-timezoned.enable = true;
  services.geoclue2.geoProviderUrl = "https://api.positon.xyz/v1/geolocate?key=56aba903-ae67-4f26-919b-15288b44bda9";
  # To use the Positon geolocation service, uncomment this URL.
  #
  # NOTE: Distributors of geoclue may only uncomment this URL if the
  #       service is used in a non-commercial manner, to quote Positon:
  #
  #         We generally consider a service or software commercial, when it is only
  #         intended to be available (beyond free trials or other restrictions) via
  #         a one-time payment, subscription, account registration or similar.
  #         Funding the development through donations or optional support contracts
  #         does not make the software itself commercial.
  #
  #         Fedora Linux, CentOS Stream, Rocky Linux or AlmaLinux all would not be
  #         considered commercial by us, neither would e.g. Debian, Ubuntu or
  #         elementary OS. However, RedHat Enterprise Linux and various SUSE Linux
  #         Enterprise versions would be considered commercial.
  #
  #       For more information, contact Positon or consult their website:
  #       https://positon.xyz/docs/

  programs.light.enable = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  kiyurica.laptop.enable = true;
  kiyurica.power-efficiency.enable = true;

  kiyurica.displaylink.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  kiyurica.gatech-vpn.enable = true;

  kiyurica.sandbox-dev.enable = true;

  assr.eduroam = {
    enable = true;
    client-cert = config.age.secrets.eduroam-client-cert.path;
    env = config.age.secrets.eduroam-env.path;
  };

  age.secrets.eduroam-client-cert = {
    file = ./eduroam-client-cert.p12.age;
    owner = "wpa_supplicant";
    group = "wpa_supplicant";
    mode = "400";
  };
  age.secrets.eduroam-env = {
    file = ./eduroam-env.age;
    mode = "400";
  };
}
