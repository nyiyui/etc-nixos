{
  config,
  libs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./fuzzel.nix
    ./wlsunset.nix
    ./wayland.nix
    (
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        config.programs.waybar.settings.mainBar =
          let
            toggleScript = pkgs.writeShellScriptBin "toggle-wvkbd" ''
              systemctl --user is-active wvkbd && systemctl --user stop wvkbd || systemctl --user start wvkbd
            '';
          in
          lib.mkIf config.nyiyui.graphical.onScreenKeyboard.enable {
            modules-left = [
              "custom/keyboard-toggle"
              "custom/fuzzel-launch"
            ];

            "custom/keyboard-toggle" = {
              exec = "echo keyboard";
              interval = "once";
              on-click = "${toggleScript}/bin/toggle-wvkbd";
            };
            "custom/fuzzel-launch" = {
              exec = "echo fuzzel";
              interval = "once";
              on-click = "${pkgs.fuzzel}/bin/fuzzel";
            };
          };
      }
    )
  ];

  options.nyiyui.sway.noBorder = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Disable window borders";
  };

  options.nyiyui.graphical.onScreenKeyboard.enable = lib.mkEnableOption "on-screen keyboard";

  config.wayland.windowManager.sway =
    let
      modifier = "Mod4";
    in
    {
      enable = true;
      wrapperFeatures.gtk = true;
      extraConfig =
        ''
          mode passthrough {
            bindsym ${modifier}+Home mode default
          }
          bindsym ${modifier}+Home mode passthrough
        ''
        + (lib.optionalString config.nyiyui.sway.noBorder ''
          default_border none
          default_floating_border none
        '');
      extraSessionCommands = ''
        export QT_AUTO_SCREEN_SCALE_FACTOR=1
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export GDK_BACKEND=wayland
        export GSK_RENDERER=gl
        export XDG_CURRENT_DESKTOP=sway
        export GBM_BACKEND=nvidia-drm
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export MOZ_ENABLE_WAYLAND=1
        export WLR_NO_HARDWARE_CURSORS=1
        export INPUT_METHOD=fcitx

        export QT_IM_MODULE=fcitx
        export GTK_IM_MODULE=fcitx
        export XMODIFIERS=@im=fcitx
        export XIM_SERVERS=fcitx
        exec systemctl --user import-environment XDG_SESSION_TYPE XDG_CURRENT_DESKTOP &
        exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=river &
      '';
      # GSK_RENDERER=gl is to fix Rnote (or GTK apps) https://github.com/flxzt/rnote/issues/1061#issuecomment-2027992630
      config = rec {
        inherit modifier;
        terminal = "foot";
        startup = [
          {
            command = "${pkgs.firefox}/bin/firefox";
            always = true;
          }
          {
            command = "${pkgs.thunderbird}/bin/thunderbird";
            always = true;
          }
        ];
        keybindings = lib.mkOptionDefault {
          # use wev to find pressed keys
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
          "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";
          "Control+grave" = "exec playerctl play-pause";
          # Screenshots
          "Print" =
            "exec ${pkgs.grim}/bin/grim - | tee ~/.cache/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy";
          "Shift+Print" =
            ''exec ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | tee ~/.cache/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy'';
          "${modifier}+Print" =
            ''exec ${pkgs.grim}/bin/grim -g "$(swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | tee ~/.cache/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy'';
          "XF86MonBrightnessUp" = "exec light -A 1";
          "XF86MonBrightnessDown" =
            ''exec fish --command='if [ "$(light)" -le 1 ]; then; light -S 1; else; light -U 1; end' '';
          "${modifier}+Alt+L" = "exec swaylock";
          "${modifier}+Shift+Return" = "exec firefox";
          "${modifier}+Alt+Shift+Return" = "exec chromium";
          "${modifier}+Return" = "exec foot";
          "${modifier}+Alt+Return" = "exec ${pkgs.rnote}/bin/rnote";
          "${modifier}+Alt+N" = "exec ${pkgs.mako}/bin/makoctl menu 'fuzzel -d' -p '通知'";
          "${modifier}+N" = "exec ${pkgs.mako}/bin/makoctl dismiss";
          "${modifier}+Shift+N" = "exec ${pkgs.mako}/bin/makoctl restore";
          "${modifier}+Shift+S" = "exec bash ${./seekback-signal.sh}";
        };
        menu = "fuzzel";
        input = {
          "*" = {
            tap = "enabled";
            xkb_options = "compose:caps";
          };
        };
        floating = {
          criteria = [
            { app_id = "urn-gtk"; }
            { app_id = "pavucontrol"; }
            { app_id = "org.rncbc.qjackctl"; }
          ];
        };
        bars = [ ];
      };
    };

  config.home.packages = with pkgs; [
    pavucontrol
    swaylock
  ];

  config.programs.waybar.settings.mainBar = {
    modules-left = [
      "sway/workspaces"
      "sway/window"
    ];

    "sway/workspaces" = {
      format = "{index}";
      disable-scroll = true;
    };
    "sway/window" = {
      format = "{title}";
    };
  };

  config.systemd.user.services.swayidle = {
    Unit = {
      Description = "swaywm: sleep, lock, etc on idle";
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart = ''
        ${pkgs.swayidle}/bin/swayidle -w \
            timeout 600 'swaymsg "output * dpms off"' \
            resume 'swaymsg "output * dpms on"' \
            timeout 3600 'systemctl suspend'
      '';
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  config.systemd.user.services.systemd-lock-handler = {
    Service = {
      ExecStart = "swaylock";
      Type = "forking";
      Restart = "on-failure";
      RestartSec = 0;
    };
    Install.WantedBy = [ "lock.target" ];
  };

  config.systemd.user.services.swaybg = {
    Unit = {
      Description = "swaywm background";
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -mfill -i ${../wallpapers/umekita.jpg}";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  config.systemd.user.services.wvkbd = lib.mkIf config.nyiyui.graphical.onScreenKeyboard.enable {
    Unit = {
      Description = "on-screen keyboard";
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart = "${pkgs.wvkbd}/bin/wvkbd-mobintl --alpha 128 -L 256";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
