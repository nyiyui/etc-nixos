{
  config,
  lib,
  pkgs,
  specialArgs,
  nixos-hardware,
  ...
}:

{
  imports = [
    specialArgs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disko-config.nix
    ./impermanence.nix
    ../secureboot.nix
    ../common.nix
    ../tpm.nix
    ../sway.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  users.users.kiyurica = {
    # abc123xyz
    initialHashedPassword = "$y$j9T$fpj7.xwcdQrY2qk9vjryQ1$cnBxWjh4W2kVWRjL1.Y5JlKH/HyJuIkiUQavRkqpFn1";
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

  networking.hostName = "misaki";

  nixpkgs.config.allowUnfree = true;

  services.udisks2.enable = true;

  kiyurica.desktop.sway.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      # "autologin" to kiyurica
      command = "uwsm start /run/current-system/sw/bin/sway";
      user = "kiyurica";
    };
  };
  home-manager.users.kiyurica =
    { ... }:
    {
      imports = [ ../home-manager/activitywatch.nix ];
      kiyurica.services.seekback.enable = true;
      wayland.windowManager.sway.config = {
        output = {
          "HDMI-A-1" = {
            mode = "3840x2160@30.000Hz";
            pos = "0 0";
            scale = "1.5";
          };
        };
      };
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

  kiyurica.programs.claude-code.enable = true;

  kiyurica.tailscale.enable = true;

  fileSystems."/home/kiyurica/inaba" = {
    device = "192.168.2.234:/inaba";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "noatime"
    ];
  };

  kiyurica.remote-builder.use-remote-builder = true;
}
