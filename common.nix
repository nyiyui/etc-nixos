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
    ./i18n.nix
    ./doas.nix
    ./home-manager.nix
    ./dbus-monitor.nix
    ./fwupd.nix
    ./ssh-agent.nix
    ./base.nix
  ];

  kiyurica.home-manager.enable = lib.mkDefault true;

  assr.wlsunset.enable = true;

  assr.gpu-screen-recorder.enable = true;

  # assr.dev-sandbox.enable = true; # TODO: broken (env vars cooked)

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = lib.mkDefault "22.11"; # Did you read the comment?

  boot.supportedFilesystems = [ "ntfs" ];

  powerManagement.cpuFreqGovernor = "performance";

  environment.systemPackages = with pkgs; [
    pciutils
    unzip
    gzip
    zip
    nix-index
    acpi
    picocom
    adwaita-icon-theme
    waypipe
  ];

  programs.dconf.enable = true;

  # Needed for xdg-document-portal (/run/user/$UID/doc) so sandboxed apps (flatpak/nixpak)
  # can write files picked via the portal.
  programs.fuse.userAllowOther = true;

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    hack-font
  ];

  # TODO: use username@hostname syntax to separate per-host home manager flake thingl
  # https://discourse.nixos.org/t/get-hostname-in-home-manager-flake-for-host-dependent-user-configs/18859/2

  home-manager.users.kiyurica = {
    imports = [ ./home-manager/common.nix ];
  };
  home-manager.extraSpecialArgs = specialArgs;

  programs.fish.enable = true;

  users.users.kiyurica = {
    extraGroups = [
      "uucp"
      "networkmanager"
      "video"
      "libvirtd"
      "dialout"
    ];
  };

  security.polkit.enable = true;

  services.udisks2.enable = true;

  services.locate.enable = true;

  networking.networkmanager.enable = true;

  services.gnome.gnome-keyring.enable = true;

  nix.settings = {
    trusted-substituters = [
      "https://cache.nixos.org?priority=10"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  virtualisation.podman.enable = true;
}
