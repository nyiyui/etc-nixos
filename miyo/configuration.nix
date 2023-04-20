{
  config,
  lib,
  pkgs,
  home-manager,
  ...
}:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      home-manager.nixosModule {}
      ../wireguard.nix
      ../doas.nix
      ../i18n.nix
      ../common.nix
      ../gensokyo.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;

  networking.hostName = "miyo";

  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

  time.timeZone = "America/Toronto";

  services.xserver.enable = true;

  services.xserver.displayManager = {
    lightdm = {
      enable = true;
    };
    autoLogin = {
      enable = true;
      user = "nyiyui";
    };
  };

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  security.polkit.enable = true;

  # Enable CUPS to print documents.
  #services.printing.enable = true;
  # no printer to print to

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Wayland
  programs.sway.enable = true;
  xdg.portal.wlr.enable = true;

  #hardware.bluetooth.enable = true;

  hardware.opengl.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

  services.xserver.screenSection = ''
    Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
    Option         "AllowIndirectGLXProtocol" "off"
    Option         "TripleBuffer" "on"
  '';

  reimu.enable = true;
  reimu.address = "10.42.0.4/32";
}
