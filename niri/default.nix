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
    ../home-manager.nix
    ./uwsm.nix
    ./set-default.nix
  ];

  options.kiyurica.desktop.niri.enable = lib.mkEnableOption "a Niri-based desktop environment";
  options.kiyurica.desktop.niri.enableUWSM = lib.mkEnableOption "UWSM support";
  options.kiyurica.desktop.niri.default = lib.mkOption {
    default = false;
    type = lib.types.bool;
    description = "set this as the default desktop environment";
  };

  config = lib.mkIf config.kiyurica.desktop.niri.enable {
    programs.niri = {
      # required for display managers (so they can run niri-session)
      enable = true;
      package = niri.packages.${pkgs.system}.niri-stable;
    };
    home-manager.users.kiyurica = {
      imports = [
        niri.homeModules.niri
        ../home-manager/graphical.nix
        ../home-manager/fuzzel.nix
        ../home-manager/wlsunset.nix
        ../home-manager/wayland.nix
        (
          {
            config,
            lib,
            pkgs,
            ...
          }:
          {
            config = {
              systemd.user.services.swaybg = {
                Unit = {
                  Description = "swaywm background";
                  PartOf = [ "graphical-session.target" ];
                  StartLimitIntervalSec = 350;
                  StartLimitBurst = 30;
                };
                Service = {
                  ExecStart = "${pkgs.swaybg}/bin/swaybg -mfill -i ${../wallpapers/takamatsu.jpg}";
                  Restart = "on-failure";
                  RestartSec = 3;
                };
                Install.WantedBy = [ "graphical-session.target" ];
              };
              systemd.user.services.import-environment = {
                Unit = {
                  Description = "Import environment variables to systemd";
                  PartOf = [ "graphical-session.target" ];
                };
                Service = {
                  Type = "oneshot";
                  ExecStart = "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP";
                  RemainAfterExit = true;
                };
                Install.WantedBy = [ "graphical-session.target" ];
              };
              programs.waybar.settings.mainBar = {
                modules-left = [
                  "niri/workspaces"
                  "niri/window"
                ];

                "niri/workspaces" = {
                  format = "{index}";
                };

                "niri/window" = {
                  rotate =
                    if config.kiyurica.waybarPosition == "left" || config.kiyurica.waybarPosition == "right" then
                      270
                    else
                      0;
                };
              };
              programs.niri = {
                enable = true;
                settings = {
                  input = {
                    keyboard = {
                      xkb.options = "compose:caps";
                      repeat-delay = 600;
                      repeat-rate = 25;
                      track-layout = "global";
                    };
                  };
                  screenshot-path = "~/.cache/screenshot.png";
                  layout = {
                    gaps = 16;
                    struts = {
                      left = 16;
                      right = 16;
                      top = 16;
                      bottom = 16;
                    };
                    focus-ring = {
                      width = 2;
                      active.color = "rgb(127 200 255)";
                      inactive.color = "rgb(80 80 80)";
                    };
                    border.enable = false;
                    default-column-width.proportion = 0.4;
                    center-focused-column = "never";
                  };
                  cursor.size = 16;
                  environment = {
                    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
                    QT_QPA_PLATFORM = "wayland";
                    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
                    GDK_BACKEND = "wayland";
                    GBM_BACKEND = "nvidia-drm";
                    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
                    MOZ_ENABLE_WAYLAND = "1";
                    WLR_NO_HARDWARE_CURSORS = "1";
                    INPUT_METHOD = "fcitx";
                    QT_IM_MODULE = "fcitx";
                    XMODIFIERS = "@im fcitx";
                    XIM_SERVERS = "fcitx";
                  };
                  animations = {
                    slowdown = 1.0;
                    workspace-switch = {
                      kind.spring.damping-ratio = 1.0;
                      kind.spring.epsilon = 0.0001;
                      kind.spring.stiffness = 1000;
                    };
                    horizontal-view-movement = {
                      kind.spring.damping-ratio = 1.0;
                      kind.spring.epsilon = 0.0001;
                      kind.spring.stiffness = 800;
                    };
                    window-open = {
                      kind.easing.duration-ms = 150;
                      kind.easing.curve = "ease-out-expo";
                    };
                    config-notification-open-close = {
                      kind.spring.damping-ratio = 0.6;
                      kind.spring.epsilon = 0.001;
                      kind.spring.stiffness = 1000;
                    };
                  };
                  binds = with config.lib.niri.actions; {
                    "Mod+Shift+Slash".action = show-hotkey-overlay;
                    "XF86MonBrightnessUp".action.spawn = [
                      "light"
                      "-A"
                      "1"
                    ];
                    "XF86MonBrightnessDown".action.spawn = [
                      "fish"
                      "--command=if [ $(light) -le 1 ]; then; light -S 1; else; light -U 1; end"
                    ];
                    "XF86AudioRaiseVolume".action.spawn = [
                      "pactl"
                      "set-sink-volume"
                      "@DEFAULT_SINK@"
                      "+1%"
                    ];
                    "XF86AudioLowerVolume".action.spawn = [
                      "pactl"
                      "set-sink-volume"
                      "@DEFAULT_SINK@"
                      "-1%"
                    ];
                    "XF86AudioMute".action.spawn = [
                      "pactl"
                      "set-sink-mute"
                      "@DEFAULT_SINK@"
                      "toggle"
                    ];
                    "XF86AudioPlay".action.spawn = [
                      "playerctl"
                      "play-pause"
                    ];
                    "Mod+Tab".action.spawn = [
                      "playerctl"
                      "play-pause"
                    ];
                    "Mod+Shift+Q".action = close-window;
                    "Mod+H".action = focus-column-left;
                    "Mod+J".action = focus-window-down;
                    "Mod+K".action = focus-window-up;
                    "Mod+L".action = focus-column-right;
                    "Mod+Shift+H".action = move-column-left;
                    "Mod+Shift+J".action = move-window-down;
                    "Mod+Shift+K".action = move-window-up;
                    "Mod+Shift+L".action = move-column-right;
                    "Mod+U".action = focus-workspace-down;
                    "Mod+I".action = focus-workspace-up;
                    "Mod+Shift+U".action = move-column-to-workspace-down;
                    "Mod+Shift+I".action = move-column-to-workspace-up;
                    "Mod+Home".action = focus-column-first;
                    "Mod+End".action = focus-column-last;
                    "Mod+Shift+Home".action = move-column-to-first;
                    "Mod+Shift+End".action = move-column-to-last;
                    "Mod+Ctrl+H".action = focus-monitor-left;
                    "Mod+Ctrl+J".action = focus-monitor-down;
                    "Mod+Ctrl+K".action = focus-monitor-up;
                    "Mod+Ctrl+L".action = focus-monitor-right;
                    "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
                    "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
                    "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
                    "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;
                    "Mod+Alt+Shift+Page_Down".action = move-workspace-down;
                    "Mod+Alt+Shift+Page_Up".action = move-workspace-up;
                    "Mod+WheelScrollDown" = {
                      cooldown-ms = 150;
                      action = focus-workspace-down;
                    };
                    "Mod+WheelScrollUp" = {
                      cooldown-ms = 150;
                      action = focus-workspace-up;
                    };
                    "Mod+Shift+WheelScrollDown" = {
                      cooldown-ms = 150;
                      action = move-column-to-workspace-down;
                    };
                    "Mod+Shift+WheelScrollUp" = {
                      cooldown-ms = 150;
                      action = move-column-to-workspace-up;
                    };
                    "Mod+WheelScrollRight".action = focus-column-right;
                    "Mod+WheelScrollLeft".action = focus-column-left;
                    "Mod+Shift+WheelScrollRight".action = move-column-right;
                    "Mod+Shift+WheelScrollLeft".action = move-column-left;
                    "Mod+1".action.focus-workspace = 1;
                    "Mod+2".action.focus-workspace = 2;
                    "Mod+3".action.focus-workspace = 3;
                    "Mod+4".action.focus-workspace = 4;
                    "Mod+5".action.focus-workspace = 5;
                    "Mod+6".action.focus-workspace = 6;
                    "Mod+7".action.focus-workspace = 7;
                    "Mod+8".action.focus-workspace = 8;
                    "Mod+9".action.focus-workspace = 9;
                    "Mod+Shift+1".action.move-column-to-workspace = 1;
                    "Mod+Shift+2".action.move-column-to-workspace = 2;
                    "Mod+Shift+3".action.move-column-to-workspace = 3;
                    "Mod+Shift+4".action.move-column-to-workspace = 4;
                    "Mod+Shift+5".action.move-column-to-workspace = 5;
                    "Mod+Shift+6".action.move-column-to-workspace = 6;
                    "Mod+Shift+7".action.move-column-to-workspace = 7;
                    "Mod+Shift+8".action.move-column-to-workspace = 8;
                    "Mod+Shift+9".action.move-column-to-workspace = 9;
                    "Mod+Comma".action = consume-window-into-column;
                    "Mod+Period".action = expel-window-from-column;
                    "Mod+BracketLeft".action = consume-or-expel-window-left;
                    "Mod+BracketRight".action = consume-or-expel-window-right;
                    "Mod+R".action = switch-preset-column-width;
                    "Mod+F".action = maximize-column;
                    "Mod+Shift+F".action = fullscreen-window;
                    "Mod+C".action = center-column;
                    "Mod+Minus".action.set-column-width = "-10%";
                    "Mod+Equal".action.set-column-width = "+10%";
                    "Mod+Shift+Minus".action.set-window-height = "-10%";
                    "Mod+Shift+Equal".action.set-window-height = "+10%";
                    "Print".action = screenshot;
                    "Alt+Print".action = screenshot-window;
                    "Mod+Shift+E".action = quit;
                    "Mod+Shift+P".action = power-off-monitors;
                  };
                  window-rules = [
                    {
                      matches = [ { app-id = "^foot$"; } ];
                      draw-border-with-background = false;
                    }
                    {
                      matches = [ { app-id = "^org\\.keepassxc\\.KeePassXC$"; } ];
                      block-out-from = "screencast";
                    }
                  ];
                  prefer-no-csd = true;
                };
              };
            };
          }
        )
      ];
    };

    environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
    services.systemd-lock-handler.enable = true;
  };
}
