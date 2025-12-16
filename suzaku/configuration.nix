{
  config,
  lib,
  pkgs,
  specialArgs,
  nixos-hardware,
  nixpkgs-unstable,
  declarative-flatpak,
  ...
}:

{
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen
    ./overlays.nix
    ./hardware-configuration.nix
    ./disko-config.nix
    ./impermanence.nix
    ../secureboot.nix
    ../fprint.nix
    ../syncthing.nix
    ../thunderbolt.nix
    ../common.nix
    ../power.nix
    ../power-efficiency.nix
    ../vlc.nix
    ../tpm.nix
    ../adb.nix
    ../vnc.nix
    ../virt.nix
    ../codex.nix
    declarative-flatpak.nixosModules.default
    ../flatpak/org.libreoffice.LibreOffice.nix
    ../flatpak/com.github.flxzt.rnote.nix
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

  kiyurica.desktop.sway.enable = true;
  kiyurica.desktop.niri = {
    enable = true;
    enableUWSM = true;
    default = false; # Keep Sway as default for laptop
  };
  kiyurica.greeter.gtkgreet.enable = true;
  home-manager.users.kiyurica =
    { pkgs, ... }:
    {
      kiyurica.hasBacklight = true;
      kiyurica.services.seekback.enable = true;
      kiyurica.services.log-window-titles.enable = true;
      # PAM requires fingerprint, so we can use touch to trigger PAM (instead of e.g. Enter key)
      programs.swaylock.settings.submit-on-touch = true;

      home.packages = [ pkgs.prusa-slicer ];

      kiyurica.services.kanshi = {
        enable = true;
        builtinDisplay = "Samsung Display Corp. 0x4152 Unknown";
      };
      services.kanshi.settings = [
        {
          output.criteria = "Samsung Display Corp. 0x4152 Unknown";
          output.mode = "2880x1800@60.001Hz";
          output.scale = 1.5;
          output.adaptiveSync = true;
        }
      ];
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

  kiyurica.networks.reimu = {
    enable = true;
    address = "10.42.0.9/32";
  };

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
  kiyurica.power-efficiency.enable = true;

  kiyurica.displaylink.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  kiyurica.networks.eduroam.enable = true;

  kiyurica.gatech-vpn.enable = true;

  services.flatpak = {
    enable = true;
    remotes = {
      "flathub" = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      "elementary" = "https://flatpak.elementary.io/repo.flatpakrepo";
    };
    packages = [
      "elementary:app/io.elementary.capnet-assist//stable"
      "flathub:app/io.github.dzheremi2.lrcmake-gtk//stable"
      "flathub:app/org.mozilla.firefox//stable"
      "flathub:app/org.gnome.World.Secrets//stable"
      "flathub:app/org.mozilla.Thunderbird//stable"
      "flathub:app/io.github.alainm23.planify//stable"
      "flathub:app/org.kde.ark//stable"
    ];
    overrides."global" = {
      Context.sockets = [
        "!fallback-x11"
        "!x11"
      ];
      Context.filesystems = [
        "!host"
        "!host-etc"
        "!host-os"
        "!home"
      ]; # just don't use apps that need this :D
    };
    overrides."org.mozilla.firefox" = {
      Context.devices = [ "dri" ];
    };
  };

  systemd.services.flatpak-permissions = {
    description = "Set permissions on /var/lib/flatpak";
    wants = [
      "manage-flatpaks-auto.service"
      "manage-flatpaks-activation.service"
    ];
    after = [
      "manage-flatpaks-auto.service"
      "manage-flatpaks-activation.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/chmod o+rX /var/lib/flatpak";
      RemainAfterExit = true;
    };
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      vpl-gpu-rt
      libvdpau-va-gl
    ];
  };

  hardware.ipu6 = {
    enable = true;
    platform = "ipu6ep";
    # cf. https://github.com/NixOS/nixpkgs/issues/225743#issuecomment-1523508154
  };

  kiyurica.sandbox-dev.enable = true;
}
