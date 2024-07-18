{ config, lib, pkgs, specialArgs, ... }: {
  imports = [ ./virt.nix ./reimu.nix ./i18n.nix ./doas.nix ./man.nix ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = lib.mkDefault "22.11"; # Did you read the comment?

  boot.supportedFilesystems = [ "ntfs" ];

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  powerManagement.cpuFreqGovernor = "performance";

  services.openssh.enable = true;
  services.fail2ban.enable = true;

  # Storage Optimisation
  nix.settings.auto-optimise-store = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    pciutils
    htop
    unzip
    gzip
    zip
    libsForQt5.ark
    nix-index
    acpi
    blueman
    file
    picocom
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    hack-font
  ];

  programs.git.enable = true;

  # TODO: use username@hostname syntax to separate per-host home manager flake thingl
  # https://discourse.nixos.org/t/get-hostname-in-home-manager-flake-for-host-dependent-user-configs/18859/2

  home-manager.users.nyiyui =
    (import ./nyiyui/nyiyui.nix { hostname = config.networking.hostName; });
  home-manager.extraSpecialArgs = specialArgs;

  users.groups.nyiyui = { };
  users.users.nyiyui = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "nyiyui";
    extraGroups =
      [ "uucp" "networkmanager" "wheel" "video" "docker" "libvirtd" "dialout" ];
    packages = with pkgs; [ firefox chromium syncthing git ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEhH+5s0m+lBC898M/nrWREaDblRCPSpL6+9wkoZdel inaba@nyiyui.ca"
    ];
    homeMode = "770";
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

  services.automatic-timezoned.enable = true;
  services.geoclue2 = {
    enable = true;
    geoProviderUrl = "https://beacondb.net/v1/geolocate";
  };
}
