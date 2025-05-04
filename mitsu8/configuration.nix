{ specialArgs, config, lib, pkgs, home-manager, nixos-hardware, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    home-manager.nixosModule
    { }
    ../base.nix
    ../i18n.nix # japanese input / language settings
    ../reimu.nix # VPN to Tokyo
    ../doas.nix # sudo replacement
    ../sound.nix
    ../sway.nix # window manager
    ../autoUpgrade-https.nix # autoupgrade scripts
    ../vlc.nix # VLC with Blu-ray decode keys
  ];

  networking.hostName = "mitsu8";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";

  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  kiyurica.desktop.sway.enable = true;
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "uwsm start /run/current-system/sw/bin/sway";
      user = "kiyurica";
    };
  };

  # not sure if required
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_CA.UTF-8";
    LC_IDENTIFICATION = "en_CA.UTF-8";
    LC_MEASUREMENT = "en_CA.UTF-8";
    LC_MONETARY = "en_CA.UTF-8";
    LC_NAME = "en_CA.UTF-8";
    LC_NUMERIC = "en_CA.UTF-8";
    LC_PAPER = "en_CA.UTF-8";
    LC_TELEPHONE = "en_CA.UTF-8";
    LC_TIME = "en_CA.UTF-8";
  };

  # required? for something I forgot
  services.libinput.enable = true;

  # Enable the OpenSSH server.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

  # Brightness adjust using e.g. `light -S 50` to set to 50%
  programs.light.enable = true;

  xdg.portal.wlr.enable = true;

  # VPN to Tokyo
  reimu.enable = true;
  reimu.address = "10.42.0.7/32";
  reimu.udp2raw.enable = false;

  # Fonts to make Japanese text look readable
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    hack-font # waybar :)
  ];

  home-manager.users.kiyurica = {
    # gamma
    services.wlsunset.temperature.night = 4000;

    # startup command line
    wayland.windowManager.sway.config.startup = lib.mkForce [
      {
        command =
          "${pkgs.chromium}/bin/chromium '--proxy-server=socks5://10.42.0.1:1080' --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36' https://tver.jp";
      }
      {
        command =
          "${pkgs.microsoft-edge}/bin/microsoft-edge '--proxy-server=socks5://10.42.0.1:1080' https://plus.nhk.jp";
      }
    ];

    # output display config
    wayland.windowManager.sway.config = {
      output = {
        "HDMI-A-2" = {
          mode = "1920x1080@60.000Hz";
          pos = "0 0";
          scale = "1";
        };
      };
    };

    # mainly for watching tv, so we don't want idle-lock
    kiyurica.graphical.idle = false;
    # borders needed for normies
    kiyurica.sway.noBorder = false;
    wayland.windowManager.sway.config.window.titlebar = true;
    # we want each window to be ~fullscreen
    wayland.windowManager.sway.extraConfig = ''
      workspace_layout tabbed
    '';
    kiyurica.graphical.background = false;
  };

  environment.systemPackages = [
    specialArgs.jts.packages.x86_64-linux.gtkui
    pkgs.hypnotix # IPTV viewer (NHK E, G, etc works)
  ];
}
