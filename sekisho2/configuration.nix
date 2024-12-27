{
  config,
  lib,
  pkgs,
  home-manager,
  specialArgs,
  ...
}:

{
  imports = [
    specialArgs.nixos-wsl.nixosModules.default
    specialArgs.agenix.nixosModules.default
    ../common.nix
    home-manager.nixosModule
    # syncthing is on Windows host (sekisho)
    ../autoUpgrade-https.nix
    ../qrystal.nix
  ];

  networking.hostName = "sekisho2";
  wsl.wslConf.network.hostname = "sekisho2";
  wsl.wslConf.network.generateResolvConf = false; # use qrystal nameservers
  wsl.wslConf.user.default = "nyiyui";

  wsl.enable = true;
  wsl.defaultUser = "nyiyui";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  services.openssh.enable = true;
}
