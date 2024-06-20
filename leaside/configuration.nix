{ config, lib, pkgs, specialArgs, home-manager, ... }:

{
  imports = [ ./hardware-configuration.nix ../autoUpgrade-https.nix ];

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

  miyamizu.services.target.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  services.getty.autologinUser = "nyiyui";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.temporary = {
    isNormalUser = true;
    description = "Temporary";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs;
      [
        firefox
        #  thunderbird
      ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  users.groups.nyiyui = { };
  users.users.nyiyui = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "nyiyui";
    extraGroups = [ "uucp" "networkmanager" "wheel" "dialout" ];
    packages = with pkgs; [ firefox chromium syncthing git ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEhH+5s0m+lBC898M/nrWREaDblRCPSpL6+9wkoZdel inaba@nyiyui.ca"
    ];
    homeMode = "770";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.                              
  users.users.temporary = {
    isNormalUser = true;
    description = "Temporary";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs;
      [
        firefox
      ];
  };

  nix.settings.trusted-users = [ "nyiyui" ];

  environment.shells = [ pkgs.fish ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [ neovim wget ];

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
}
