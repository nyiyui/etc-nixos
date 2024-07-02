{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../autoUpgrade-https.nix
    ../base.nix
    ./github-runner.nix
    ../qrystal2.nix
  ];

  networking.hostName = "leaside";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  xdg.portal.wlr.enable = true;
  xdg.portal.config.common.default = "*";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  services.getty.autologinUser = "nyiyui";

  users.users.temporary = {
    isNormalUser = true;
    description = "Temporary";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ firefox ];
  };

  environment.systemPackages = with pkgs; [
    neovim
    wget
  ];
}
