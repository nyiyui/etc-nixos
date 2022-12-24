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

  time.timeZone = "America/Toronto";

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

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
  
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    git
  ];

  networking.firewall.allowedTCPPorts = [ 22 ];
}
