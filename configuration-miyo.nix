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
      ./hardware-configuration-miyo.nix
      ./dns.nix
      ./wireguard.nix
      ./doas.nix
      ./i18n.nix
      ./common.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "miyo"; # Define your hostname.

  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

  time.timeZone = "America/Toronto";

  services.xserver.enable = true;

  services.xserver.displayManager.lightdm.enable = true;

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };
  # Brightness adjust
  programs.light.enable = true;

  # Wayland
  programs.sway.enable = true;
  xdg.portal.wlr.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}
