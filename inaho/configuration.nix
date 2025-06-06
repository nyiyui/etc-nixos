{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disko-config.nix
    ./impermanence.nix
    ../base.nix
    ../secureboot.nix
    ../syncthing.nix
    ../autoUpgrade-git.nix
    specialArgs.disko.nixosModules.disko
    ./backup.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  users.users.kiyurica = {
    initialHashedPassword = "$y$j9T$2YLxBn0e/Bw6b3k9/qpCi1$Rq6BUgPFLxOVypwgEYeLjbORXCVnbZ2wCRR2yGPSoL7";
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

  networking.hostName = "inaho";

  nixpkgs.config.allowUnfree = true;

  services.udisks2.enable = true;

  home-manager.users.kiyurica = { ... }: { };

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

  system.autoUpgrade.dates = lib.mkForce "02:30";

  services.syncthing.settings.folders."inaba".path = lib.mkForce "/inaba";
  services.syncthing.settings.folders."geofront".path = lib.mkForce "/GF-01";

  kiyurica.tailscale.enable = true;

  # provide access to inaba for misaki
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /inaba  192.168.2.201(rw,no_subtree_check)
  '';
  networking.firewall.allowedTCPPorts = [ 2049 ];

  kiyurica.remote-builder.enable = true;

  services.minecraft-server = {
    enable = true;
    eula = true;
    declarative = true;
    serverProperties = {
      server-port = 25565;
      online-mode = false; # needed for clients w/o Mojang account
    };
    openFirewall = true;
  };

  services.ollama = {
    enable = true;
    loadModels = [
      "llama4"
      "llama3.3"
    ];
  };
}
