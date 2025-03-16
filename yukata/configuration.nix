{
  specialArgs,
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
    ../base.nix
    ../headless.nix
    ../thunderbolt.nix
    ../autoUpgrade-https.nix
    ../home-manager.nix
    ./ollama.nix
    ../cosense-vector-search
  ];

  networking.hostName = "yukata";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

  boot.kernelParams = [ "nomodeset" ]; # wack drivers ig

  kiyurica.services.cosense-vector-search = {
    enable = true;
    virtualHost = "https://cosense-vector-search.etc.kiyuri.ca";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
