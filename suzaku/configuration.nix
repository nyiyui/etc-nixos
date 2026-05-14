{
  config,
  lib,
  pkgs,
  specialArgs,
  nixos-hardware,
  nixpkgs-unstable,
  ...
}:

{
  imports = [
    # ./kernel-modules.nix # TODO: WPA3
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen
    ./overlays.nix
    ./hardware-configuration.nix
    ./disko-config.nix
    ../appliance
    ./impermanence.nix
    ./nix-copy.nix
    ../secureboot.nix
    ../fprint.nix
    ../syncthing.nix
    ../thunderbolt.nix
    ../common.nix
    ../sound.nix
    ../vlc.nix
    ../tpm.nix
    ../adb.nix
    ../vnc.nix
    ../virt.nix
    # ../codex.nix # not used
    ../nixpak/packages/org.keepassxc.KeePassXC.nix
    ../nixpak/packages/org.kde.ark.nix
    ../nixpak/packages/org.mozilla.firefox.nix
    ../nixpak/packages/org.mozilla.Thunderbird.nix
    # ../nixpak/packages/org.libreoffice.LibreOffice.nix
    ../nixpak/packages/io.github.alainm23.planify.nix
    ../nixpak/packages/org.signal.Signal.nix
    ../nixpak/packages/org.strawberrymusicplayer.strawberry.nix
    # ../nixpak/packages/org.chromium.Chromium.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  users.users.kiyurica = {
    initialHashedPassword = "$y$j9T$g5xm0pLBFbK4W4c5BIENt/$D18bkwRRxH/MjSlInTZfvd2vE4Mxa.RQXARitTirV64";
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?

  networking.hostName = "suzaku";

  nixpkgs.config.allowUnfree = true;

  services.udisks2.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };

  kiyurica.desktop.niri = {
    enable = true;
    enableUWSM = true;
  };
  kiyurica.greeter.gtkgreet = {
    enable = true;
  };
  home-manager.users.kiyurica =
    { pkgs, ... }:
    {
      kiyurica.hasBacklight = true;

      home.packages = [
        pkgs.prusa-slicer
        pkgs.moonlight-qt
      ];

      programs.niri.settings.outputs."Samsung Display Corp. 0x4152 Unknown" = {
        mode = {
          width = 2880;
          height = 1800;
          refresh = 60.001;
        };
        scale = 1.25;
        variable-refresh-rate = true;
      };

      kiyurica.icsUrlPath = config.age.secrets.icsUrlPath.path;
    };

  age.secrets.icsUrlPath = {
    file = ../secrets/ics-url-path.txt.age;
    owner = "kiyurica";
    group = "kiyurica";
    mode = "400";
  };

  autoUpgrade.directFlake = true;

  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

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

  services.udev.extraRules = lib.mkAfter ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00fc", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
  '';

  kiyurica.tailscale.enable = true;
  systemd.services.tailscaled-autoconnect.wantedBy = lib.mkForce [ ]; # we may not always be connected to the Internet and therefore the tailnet

  # Enable mDNS for LAN hostname resolution
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  kiyurica.laptop.enable = true;

  kiyurica.displaylink.enable = true;

  kiyurica.networks.eduroam.enable = true;

  kiyurica.gatech-vpn.enable = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt
      libvdpau-va-gl
    ];
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
  environment.systemPackages = with pkgs; [
    intel-gpu-tools
  ];

  kiyurica.quaderno-sync = {
    enable = true;
    autoSync.enable = true;
  };

  assr.power-logger.enable = true;

  # TODO: Enable when Fall 2026 semester starts
  # kiyurica.caldav-canvas-gradescope = {
  #   enable = true;
  #   credFile = ./caldav-canvas-gradescope-env.cred;
  # };

  nix.settings.cores = 16; # keep at least 4 cores open for UI

  assr.ssh-agent.implementation = "ssh-tpm-agent";

  services.tlp.settings = {
    DISK_DEVICES = "nvme0n1";
    PLATFORM_PROFILE_ON_BAT = "low-power";
    DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wwan";
  };

  boot.initrd.systemd.repart.device = "/dev/disk/by-id/nvme-CT2000P3PSSD8_2506E9A48456";
}
