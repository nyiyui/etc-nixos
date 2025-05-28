{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}:
{
  imports = [
    ./all-modules.nix
    ./reimu.nix
    ./i18n.nix
    ./doas.nix
    ./man.nix
    ./home-manager.nix
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = lib.mkDefault "22.11"; # Did you read the comment?

  boot.supportedFilesystems = [ "ntfs" ];

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  powerManagement.cpuFreqGovernor = "performance";

  services.openssh.enable = true;
  services.fail2ban.enable = true;

  # Storage Optimisation
  nix.settings.auto-optimise-store = true;

  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  environment.systemPackages = with pkgs; [
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
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    hack-font
  ];

  programs.git.enable = true;

  # TODO: use username@hostname syntax to separate per-host home manager flake thingl
  # https://discourse.nixos.org/t/get-hostname-in-home-manager-flake-for-host-dependent-user-configs/18859/2

  home-manager.users.kiyurica = {
    imports = [ ./home-manager/common.nix ];
  };
  home-manager.extraSpecialArgs = specialArgs;

  users.groups.kiyurica = { };
  users.users.kiyurica = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "kiyurica";
    extraGroups = [
      "uucp"
      "networkmanager"
      "wheel"
      "video"
      "libvirtd"
      "dialout"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEhH+5s0m+lBC898M/nrWREaDblRCPSpL6+9wkoZdel inaba@nyiyui.ca"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBBbPVUjEWdEEWgE7z78euFUVJtNzQ4267esBzytfqeWmGhfjkEoe9TdJRvOily0jn0TVrvAxdXYqMksB4WUkhfY="
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHIr5uQCGECocHl3JKYH9etRA0NOdg9N9+d9ElgPYuCT+Iw3yeA+GAcArfPADxfSqjhpITPJkxWsSdaNmKLrgpA= kiyurica@suzaku.dev.kiyuri.ca"
    ];
    homeMode = "770";
  };

  nix.settings.trusted-users = [ "kiyurica" ];

  environment.shells = [ pkgs.fish ];

  # Polkit
  security.polkit.enable = true;

  services.udisks2.enable = true;

  services.locate.enable = true;

  networking.networkmanager.enable = true;
}
