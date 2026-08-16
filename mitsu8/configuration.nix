{
  specialArgs,
  config,
  lib,
  pkgs,
  home-manager,
  nixos-hardware,
  nixpkgs-unstable,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    { }
    ../home-manager.nix
    ../base.nix
    ../i18n.nix # japanese input / language settings
    ../doas.nix # sudo replacement
    ../sound.nix
    ../niri # window manager
  ];

  users.users.root.initialHashedPassword = "$y$j9T$hIH10tdwuxQdhSkN6D9vb0$dKJd1SITL.iGfrn8soMLLNyQxvoM0o0MIrmuS.6HuA7";

  kiyurica.home-manager.enable = true;

  autoUpgrade.directFlake = true;

  networking.hostName = "mitsu8";

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.loader.efi.efiSysMountPoint = "/boot/efi";

  kiyurica.desktop.niri = {
    enable = true;
    enableUWSM = true;
  };

  assr.wlsunset.temperature.night = 4000;

  services.greetd = {
    enable = true;
    settings.default_session = {
      # "autologin" to kiyurica
      command = "uwsm start /run/current-system/sw/bin/niri";
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

  xdg.portal.wlr.enable = true;

  # Fonts to make Japanese text look readable
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
  ];

  home-manager.users.kiyurica =
    { pkgs, ... }:
    {
      # mitsu8 must stay awake so scheduled OS upgrades (see autoUpgrade-git.nix) can run
      kiyurica.graphical.idle = false;

      # startup command line
      programs.niri.settings.spawn-at-startup = [
        {
          sh = "${pkgs.chromium}/bin/chromium --password-store=basic '--proxy-server=socks5://tk2-246-32584.tailcbbed9.ts.net:1080' --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36' https://tver.jp";
        }
        {
          sh = "${pkgs.microsoft-edge}/bin/microsoft-edge --password-store=basic '--proxy-server=socks5://tk2-246-32584.tailcbbed9.ts.net:1080' https://www.web.nhk";
        }
      ];

      systemd.user.services.wayvnc = {
        Unit = {
          Description = "VNC server for lenovo-801lv";
          RestartSec = 30;
          # no limit, as the display may come back at any time (proper soln is to listen for when display comes back, but too lazy for that)
        };
        Service = {
          ExecStart = "${pkgs.wayvnc}/bin/wayvnc 0.0.0.0";
          Restart = "always";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # output display config
      programs.niri.settings.outputs."HDMI-A-2" = {
        # 1080p is enough and don't want to stress the GPU too much
        mode.width = 1920;
        mode.height = 1080;
        mode.refresh = 60.0;
        position.x = 0;
        position.y = 0;
        scale = 1;
      };

      kiyurica.service-status = [
        {
          serviceName = "tailscaled.service";
          key = "VPN";
        }
      ];

      # default for windows to use the full screen
      programs.niri.settings.layout.default-column-width.proportion = lib.mkForce 1.0;
    };

  environment.systemPackages = [
    pkgs.hypnotix # IPTV viewer (NHK E, G, etc works)
  ];

  kiyurica.tailscale.enable = true;

  # mitsu8 is not particularly powerful and we want to prioritize TV
  nix = {
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
  };
}
