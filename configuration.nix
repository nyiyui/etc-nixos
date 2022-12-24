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
      ./hardware-configuration.nix
      ./dns.nix
      ./wireguard.nix
      ./doas.nix
      ./i18n.nix
      ./common.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  networking.hostName = "kumi";

  networking.networkmanager.enable = true;

  programs.nm-applet.enable = true;

  time.timeZone = "America/Toronto";

  services.xserver.enable = true;

  services.xserver.displayManager.lightdm.enable = true;

  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Polkit
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

  # Syncthing
  networking.firewall = {
    allowedUDPPorts = [ 22000 21027 ];
    allowedTCPPorts = [ 22 22000 ];
  };

  # Brightness adjust
  programs.light.enable = true;

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "nyiyui";

  # Wayland
  programs.sway.enable = true;
  xdg.portal.wlr.enable = true;

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };
  hardware.opengl = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
      vaapiIntel         # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime
    ];
  };

  services.upower.enable = true;
  services.upower.criticalPowerAction = "Hibernate";
  services.logind = {
    lidSwitchExternalPower = "ignore";
    extraConfig = ''
      HandlePowerKey=ignore
    '';
  };

  hardware.bluetooth.enable = true;
}
