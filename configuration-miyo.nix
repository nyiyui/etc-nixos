{
  config,
  lib,
  pkgs,
  home-manager,
  nixos-hardware,
  ...
}:

{
  imports =
    [ # Include the results of the hardware scan.
      home-manager.nixosModule {}
      nixos-hardware.nixosModules.system76
      ./hardware-configuration-miyo.nix
      ./dns.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "miyo"; # Define your hostname.

  networking.networkmanager.enable = true;

  time.timeZone = "America/Toronto";

  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-hangul
      fcitx5-gtk
    ];
  };

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  users.groups.nyiyui = {};
  users.users.nyiyui = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "nyiyui";
    extraGroups = [ "uucp" "networkmanager" "wheel" "video" "docker" "libvirtd" ];
    packages = with pkgs; [
      firefox
      chromium
      syncthing
      sway
      git
    ];
    shell = pkgs.fish;
  };
  home-manager.users.nyiyui = (import ./nyiyui/nyiyui.nix);


  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
  ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ 22 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
