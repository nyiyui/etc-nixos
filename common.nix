{ config, pkgs, ... }:
{
  imports = [
    ./dns.nix
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  boot.supportedFilesystems = [ "ntfs" ];

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Docker
  virtualisation.docker.enable = true;

  virtualisation.libvirtd = {
    enable = true;
  };

  powerManagement.cpuFreqGovernor = "performance";

  services.openssh.enable = true;

  # GC
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";

  # Storage Optimisation
  nix.settings.auto-optimise-store = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  #virtualisation.vmware.host.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl 
    pciutils
    neovim
    htop
    system76-firmware
    unzip
    gzip
    zip
    libsForQt5.ark
    nix-index
    acpi
    qemu_full
    virt-manager
    blueman
    file
    picocom
  ];

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    hack-font
  ];

  services.picom.enable = true;

  programs.git.enable = true;

  home-manager.users.nyiyui = (import ./nyiyui/nyiyui.nix {
    hostname = config.networking.hostName;
  });

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
      git
    ];
    shell = pkgs.fish;
  };

  nix.settings.trusted-users = [ "nyiyui" ];

  environment.shells = [ pkgs.fish ];

  # Syncthing
  networking.firewall = {
    allowedUDPPorts = [ 22000 21027 ];
    allowedTCPPorts = [ 22 22000 ];
  };

  # Polkit
  security.polkit.enable = true;

  # KDE workaround
  programs.dconf.enable = true;

  services.udisks2.enable = true;

  services.locate.enable = true;
}
