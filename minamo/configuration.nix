{
  config,
  lib,
  pkgs,
  specialArgs,
  ...
}:

{
  imports = [
    ./disko-config.nix
    ./impermanence.nix
    ./build-suzaku.nix
    ../secureboot.nix
    specialArgs.disko.nixosModules.disko
    ../autoUpgrade-git.nix
    ../tpm.nix
    ../common.nix
    ../syncthing.nix
    ../vlc.nix
    ../adb.nix
    ../virt.nix
    ../codex.nix
    ../nixpak/packages/org.signal.Signal.nix
    ../nixpak/packages/org.mozilla.firefox.nix
    ../nixpak/packages/org.chromium.Chromium.nix
  ];

  boot.initrd.systemd.enable = true;

  boot.initrd.availableKernelModules = [
    "nvme"
  ];
  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "r8168" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.r8168 ];
  boot.blacklistedKernelModules = [ "r8169" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ]; # enables nvidia support
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  users.users.kiyurica = {
    hashedPassword = "$y$j9T$lNSNPobnQX.GuwkdK4m.g0$/ivj88dtnxodfbZ1gmjn6AkabMh32qzsYjHr5i7jjD/";
  };

  environment.systemPackages = with pkgs; [
    ethtool
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 0;

  system.stateVersion = "25.05";

  networking.hostName = "minamo";
  # Note: Also run `run0 nmcli c modify '有線接続 1' 802-3-ethernet.wake-on-lan magic`
  # if the following doesn't suffice or is overridden by NetworkManager.
  networking.interfaces.enp39s0.wakeOnLan.enable = true;
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "America/New_York";

  autoUpgrade.directFlake = true;
  boot.initrd.systemd.emergencyAccess = true;

  services.udisks2.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ "/" ];
  };
  kiyurica.desktop.niri = {
    enable = true;
    enableUWSM = true;
    default = true;
  };
  kiyurica.greeter.gtkgreet.enable = true;
  kiyurica.tailscale.enable = true;

  # Enable mDNS for LAN hostname resolution
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  home-manager.users.kiyurica =
    { lib, ... }:
    {
      kiyurica.waybarPosition = "right";
      programs.waybar.style = ''
        window#waybar {
          background-color: rgba(0, 0, 0, 1);
        }
      '';
      programs.niri.settings.layout.default-column-width.proportion = lib.mkForce 0.3;
    };

  kiyurica.ics-next-event.icsUrlPath = config.age.secrets.icsUrlPath.path;

  age.secrets.icsUrlPath = {
    file = ../secrets/ics-url-path.txt.age;
    owner = "kiyurica";
    group = "kiyurica";
    mode = "400";
  };

  kiyurica.networks.aiden = {
    enable = true;
    address = "192.168.2.100/32";
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.rootless.enable = true;
  programs.singularity.enable = true;
  programs.singularity.package = pkgs.apptainer;

  kiyurica.gatech-vpn.enable = true;

  kiyurica.ollama.enableServer = true;

  assr.dev-sandbox.enable = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
