{
  specialArgs,
  config,
  nixos-hardware,
  nixpkgs-unstable,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../base.nix
    ../i18n.nix # japanese input / language settings
    ./motioneye.nix
    ./dante.nix
  ];

  users.users.root.initialHashedPassword = "$y$j9T$hIH10tdwuxQdhSkN6D9vb0$dKJd1SITL.iGfrn8soMLLNyQxvoM0o0MIrmuS.6HuA7";

  autoUpgrade.directFlake = true;

  networking.hostName = "mitsu8";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Enable the OpenSSH server.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  services.resolved.enable = true;

  kiyurica.tailscale.enable = true;

  # mitsu8 is not particularly powerful
  nix = {
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
  };
}
