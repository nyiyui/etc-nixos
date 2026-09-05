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
    environment.systemPackages = [
      pkgs.brightnessctl
      (pkgs.writeShellApplication {
        name = "brightness-notify";
        runtimeInputs = [
          pkgs.brightnessctl
          pkgs.notify-desktop
        ];
        text = ''
          delta="''${1:?usage: $0 <brightnessctl delta>}"

          percent=$(brightnessctl set "$delta" -m | cut -d, -f4 | cut -d% -f1)

          id_file="$XDG_RUNTIME_DIR/brightness-notif-id"
          id=$(cat "$id_file" 2>/dev/null || echo 0)
          notify-desktop -r "$id" -a brightness -u low -t 1500 "$percent%" >"$id_file"
        '';
      })
    ];
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
          exec = pkgs.writeShellScript "waybar-image-version" ''
            ${pkgs.gawk}/bin/awk -F= '
              $1 == "IMAGE_VERSION" {
                gsub(/^"|"$/, "", $2);
                print $2;
                found = 1;
                exit;
              }
              END {
                if (!found) print "unknown";
              }
            ' /etc/os-release
          '';
          interval = "once";
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
      xwayland # to run X wms inside Wayland
      xwayland-run
      xwayland-satellite
      swaylock
      foot
      wdisplays # display configurator GUI
    ];

    xdg.portal = {
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk # TODO: needed?
      ];
      config.niri = {
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
      };
      xdgOpenUsePortal = true;
    };

    # environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
    services.systemd-lock-handler.enable = true;
  };
}
