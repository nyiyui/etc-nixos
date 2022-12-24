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
      #builtins.fetchGit { url="https://github.com/stites/system76-nixos"; ref="946dbc3a0e222b925b91d140d44afc5f51a39053"; }
      ./dns.nix
    ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  networking.hostName = "kumi";
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Enable network manager applet
  programs.nm-applet.enable = true;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the LXQT Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;

  # Configure keymap in X11
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
      sway
      git
    ];
    shell = pkgs.fish;
  };
  home-manager.users.nyiyui = (import ./nyiyui/nyiyui.nix);

  environment.shells = [ pkgs.fish ];

  # Brightness adjust
  programs.light.enable = true;
  programs.git.enable = true;

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "nyiyui";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl 
    pciutils
    wireguard-tools
    neovim
    htop
    system76-firmware
    unzip
    gzip
    realvnc-vnc-viewer
    zip
    libsForQt5.ark
    #nix-index
    acpi
    qemu_full
    virt-manager
    blueman
  ];

  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    hack-font
  ];

  services.picom.enable = true;

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
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Priviledge Escalation
  security.sudo.enable = false;
  security.doas.enable = true;
  security.doas.extraRules = [ {
    users = [ "nyiyui" ];
    keepEnv = true;
    noPass = true;  
  } ];

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # WireGuard
  networking.nat.enable = true;
  networking.nat.externalInterface = "eth0";
  networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedUDPPorts = [ 28607 ]
                    ++ [ 22000 21027 ]; # syncthing
    allowedTCPPorts = [ 22000 ]; # syncthing
  };
  networking.wireguard.interfaces = {
    kimihenokore = {
      ips = [ "10.5.0.93/32" ];
      privateKeyFile = "/etc/nixos/wireguard-privkey";
      peers = [
        {
          publicKey = "EYxF76Poj9O1mV3bhvQ1UXdewvHcI+dDi70f3qmGOS0=";
          presharedKey = "/jzIkELQRwrCylbArtUuXzHMwCcphm5H0evjke9iD2A=";
          allowedIPs = [ "10.5.0.0/24" ];
          endpoint = "kimihenokore.nyiyui.ca:28607";
          persistentKeepalive = 30;
        }
      ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  # GC
  nix.gc.automatic = true;
  nix.gc.dates = "weekly";

  # Storage Optimisation
  nix.settings.auto-optimise-store = true;

  services.upower.enable = true;
  services.upower.criticalPowerAction = "Hibernate";
  services.logind = {
    lidSwitch = "suspend";
    extraConfig = ''
      HandlePowerKey=ignore
    '';
  };

  # Docker
  virtualisation.docker.enable = true;

  virtualisation.libvirtd = {
    enable = true;
  };

  powerManagement.cpuFreqGovernor = "performance";

  #systemd.services.mitsuha = {
  #  enable = true;
  #  description = "set cpupower governor depending on battery state";
  #  wantedBy = [ "multi-user.target" ];
  #  unitConfig = {
  #    #StartLimitIntervalSec = 350;
  #    #StartLimitBurst = 30;
  #  };
  #  environment = {
  #    CPUPOWER = "${pkgs.cpupower}/bin/cpupower";
  #  };
  #  serviceConfig = {
  #    ExecStart = "${pkgs.bash}/bin/bash " + ./mitsuha.sh;
  #    #Restart = "on-failure";
  #    #RestartSec = 3;
  #  };
  #};

  hardware.bluetooth.enable = true;

  # Fcitx
  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-hangul
      fcitx5-gtk
    ];
  };
}
