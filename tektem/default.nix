# Tech Team configuration
{ config, pkgs, ... }: let
in {
  import = [
    ./autoUpgrade-https.nix
    ./i18n.nix
    ./doas.nix
    ./vlc.nix
  ];
  home-manager.users.nyiyui =
    (import ./nyiyui/tektem.nix { hostname = config.networking.hostName; });
  home-manager.extraSpecialArgs = specialArgs;

  boot.supportedFilesystems = [ "ntfs" ];
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  powerManagement.cpuFreqGovernor = "performance";
  services.openssh.enable = true;
  nix.settings.auto-optimise-store = true;
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    neovim
    wget
    curl
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
    yt-dlp
  ];

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    hack-font
  ];

  programs.git.enable = true;

  environment.shells = [ pkgs.fish ];

  users.groups.nyiyui = { };
  users.users.nyiyui = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "nyiyui";
    extraGroups =
      [ "uucp" "networkmanager" "wheel" "video" "dialout" ];
    packages = with pkgs; [ firefox git ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEhH+5s0m+lBC898M/nrWREaDblRCPSpL6+9wkoZdel inaba@nyiyui.ca"
    ];
    homeMode = "770";
  };

  services.udisks2.enable = true;
  services.automatic-timezoned.enable = true;
}
