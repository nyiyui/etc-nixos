{
  config,
  pkgs,
  lib,
  nixpkgs-unstable,
  niri,
  ...
}:
{
  imports = [
    ./uwsm.nix
    ./set-default.nix
  ];

  options.assr.desktop.niri.enable = lib.mkEnableOption "a Niri-based desktop environment";
  options.assr.desktop.niri.enableUWSM = lib.mkEnableOption "UWSM support";
  options.assr.desktop.niri.default = lib.mkOption {
    default = false;
    type = lib.types.bool;
    description = "set this as the default desktop environment";
  };

  config = lib.mkIf config.assr.desktop.niri.enable {
    hjem.users.kiyurica = {
      enable = true;
      imports = [
        ../hjem/graphical.nix
        ../hjem/wayland.nix
        ../hjem/fuzzel.nix
      ];
      rum.desktops.niri = {
        enable = true;
        config = (builtins.readFile ./config.kdl);
      };
      xdg.config.files."waybar/config".value = {
        modules-left = [
          "niri/workspaces"
          "niri/window"
        ];
        modules-center = [
          "custom/image-version"
        ];
        "niri/workspaces".format = "{index}";
        "custom/image-version" = {
          format = "{}";
          exec = "${pkgs.gawk}/bin/awk -F= '$1==\"IMAGE_VERSION\" {gsub(/^\"|\"$/, \"\", $2); print $2; exit}' /etc/os-release";
          interval = 86400;
        };
      };
      systemd.services.swaybg = {
        description = "swaywm background";
        requires = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        startLimitIntervalSec = 350;
        startLimitBurst = 30;
        serviceConfig = {
          ExecStart = "${pkgs.swaybg}/bin/swaybg -mfill -i ${../wallpapers/c11-207.jpg}";
          Restart = "on-failure";
          RestartSec = 3;
        };
        wantedBy = [ "graphical-session.target" ];
      };
      systemd.services.swaylock = {
        wantedBy = [ "lock.target" ];
        unitConfig = {
          OnSuccess = [ "unlock.target" ];
          PartOf = [ "lock.target" ];
          After = [ "lock.target" ];
        };
        serviceConfig = {
          Type = "forking";
          ExecStart = "${pkgs.swaylock}/bin/swaylock -f";
          Restart = "on-failure";
          RestartSec = "0";
        };
      };
    };

    programs.niri = {
      # required for display managers (so they can run niri-session)
      enable = true;
    };

    users.users.kiyurica.packages = with pkgs; [
      xwayland-satellite
      swaylock
      foot
    ];

    xdg.portal = {
      enable = true;
      # https://github.com/YaLTeR/niri/wiki/Screencasting
      # Use GTK portal for the file picker; keep GNOME portal available for screencasting.
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config.niri = {
        default = "gtk";
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
      };
      xdgOpenUsePortal = true;
    };

    # environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
    services.systemd-lock-handler.enable = true;
  };
}
