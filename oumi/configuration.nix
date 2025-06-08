{
  config,
  lib,
  pkgs,
  agenix,
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
    ../autoUpgrade-git.nix
    specialArgs.disko.nixosModules.disko
    agenix.nixosModules.default
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  users.users.kiyurica = {
    initialHashedPassword = "$y$j9T$njiXQoNnonW1GMVeE3f7I/$65ANSfcChtOgqTSmnU2oBxo3LTdzCOAX/YhTwiGAl92";
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

  networking.hostName = "oumi";

  nixpkgs.config.allowUnfree = true;

  services.udisks2.enable = true;

  home-manager.users.kiyurica = { ... }: { };

  autoUpgrade.directFlake = false;

  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  time.timeZone = "America/Toronto";

  programs.light.enable = true;

  system.autoUpgrade.dates = lib.mkForce "02:30";

  kiyurica.tailscale.enable = false;
  # networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
  #   config.services.ollama.port
  # ];

  kiyurica.remote-builder.enable = false;
}

