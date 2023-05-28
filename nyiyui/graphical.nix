{ config, libs, pkgs, lib, ... }:

{
  imports = [./swayidle.nix];
  i18n.inputMethod = {
    enabled = "fcitx5";
    #fcitx.engines = with pkgs.fcitx-engines; [ mozc hangul ];
    fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-hangul fcitx5-gtk ];
  };

  programs.waybar = {
    # TODO: run systemctl --user restart waybar on activation
    enable = true;
    systemd.enable = true;
    style = builtins.readFile ./waybar.css;
    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        height = 16;
        output = [ "eDP-1" "DP-1" ];
        modules-left = [ "sway/workspaces" ];
        modules-center = [ "sway/window" ];
        modules-right =
          [ "tray" "network" "temperature" "pulseaudio" "battery" "clock" ];

        "battery" = {
          states.warning = 20;
          states.critical = 10;
          format = "{capacity} {time}";
          tooltip-format = "{power}W";
          format-time = "{H}:{m}";
        };
        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };
        "sway/window" = {
          format = "{app_id} {title}";
          icon = true;
        };
        "clock" = {
          format = "{:%H:%M %Y-%m-%d}";
          tooltip-format = "{calendar}";
          calendar = {
            mode = "month";
            weeks-pos = "left";
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
            actions = {
              on-click-right = "mode";
              on-click-forward = "tz_up";
              on-click-backward = "tz_down";
              on-scroll-up = "shift_up";
              on-scroll-down = "shift_down";
            };
          };
        };
        "network" = {
          format = "{ifname}";
          format-wifi = "{essid} {signaldBm}";
          format-disconnected = "";
          on-click = "${pkgs.foot}/bin/foot ~/wifi_conn_new";
          tooltip-format =
            "{ifname} {ipaddr} {bandwidthUpOctets} {bandwidthUpOctets}";
          tooltip-format-wifi =
            "{ifname} {essid} {signaldBm} dBm {frequency} MHz {ipaddr} {bandwidthUpOctets} {bandwidthUpOctets}";
          tooltip-format-disconnected = "切断";
        };
        "pulseaudio" = {
          format-icons = {
            headphone = "ﾍ";
            hdmi = "H";
            bluetooth = "ᛒ";
          };
          format = "{volume}{icon}";
          format-bluetooth = "{volume}{icon}";
          on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
          ignored-sinks = [ "Easy Effects Sink" ];
        };
      };
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    extraConfig = ''
      default_border none
      default_floating_border none
    '';
    extraSessionCommands = ''
      export QT_AUTO_SCREEN_SCALE_FACTOR=1
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export GDK_BACKEND=wayland
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
    '';
    config = rec {
      modifier = "Mod4";
      terminal = "foot";
      startup = [
        {
          command = "systemctl --user restart waybar";
          always = true;
        }
        {
          command = "systemctl --user restart wlsunset";
          always = true;
        }
        {
          command =
            "${pkgs.foot}/bin/foot ssh-add $(ls -1 ~/.ssh/id_* | grep -v '\\.pub$')";
        }
      ];
      keybindings = lib.mkOptionDefault {
        # use wev to find pressed keys
        "XF86Go" = "exec playerctl play-pause";
        "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioRaiseVolume" =
          "exec pactl set-sink-volume @DEFAULT_SINK@ +1%";
        "XF86AudioLowerVolume" =
          "exec pactl set-sink-volume @DEFAULT_SINK@ -1%";
        "XF86AudioPlay" = "exec playerctl play-pause";
        # Screenshots 
        "Print" =
          "exec ${pkgs.grim}/bin/grim - | tee ~/.cache/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy";
        "Shift+Print" = ''
          exec ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | tee ~/.cache/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy'';
        "${modifier}+Print" = ''
          exec ${pkgs.grim}/bin/grim -g "$(swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | tee ~/.cache/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy'';
        "XF86MonBrightnessUp" = "exec light -A 1";
        "XF86MonBrightnessDown" = ''exec fish --command='if [ "$(light)" -le 1 ]; then; light -S 1; else; light -U 1; end' '';
        "${modifier}+Shift+Return" = "exec chromium";
        "${modifier}+Return" = "exec foot";
        "${modifier}+Alt+Return" = "exec ${pkgs.rnote}/bin/rnote";
        "${modifier}+Alt+N" =
          "exec ${pkgs.mako}/bin/makoctl menu dmenu -p '通知'";
        "${modifier}+N" = "exec ${pkgs.mako}/bin/makoctl dismiss";
        "${modifier}+Shift+N" = "exec ${pkgs.mako}/bin/makoctl restore";
      };
      menu = "dmenu_run";
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

  programs.mako = {
    enable = true;
    anchor = "bottom-right";
    font = "Roboto 14";
    backgroundColor = "#00000050";
    textColor = "#86cecb";
    #FORMAT SPECIFIERS
    #Format specification works similarly to printf(3), but with a different set of specifiers.
    #%% Literal "%"
    #\\ Literal "\"
    #\n New Line
    #For notifications
    #%a Application name
    #%s Notification summary
    #%b Notification body
    #%g Number of notifications in the current group
    #%i Notification id
    #For the hidden notifications placeholder
    #%h Number of hidden notifications
    #%t Total number of notifications
    extraConfig = ''
      max-history=65536
      format=<b>%s</b>\n%b\n%a %i
      [grouped=true]
      format=%g : %a <b>%s</b>\n%b\n%i
      [hidden=true]
      format=%t / %h
      [urgency=low]
      border-size=0

      [urgency=normal]
      border-color=#cb86ce

      [urgency=critical]
      border-color=#ffffff
    '';
  };
  home.packages = with pkgs;
    [
      jq # required by mako for e.g. mako menu
    ];

  gtk.theme = { name = "Adwaita-dark"; };

  programs.swaylock = {
    #enable = true;
    settings = {
      ignore-empty-password = false;
      show-failed-attempts = true;
      show-keyboard-layout = true;
      color = "000000";
      inside-color = "000000";
      inside-clear-color = "000000";
      inside-caps-lock-color = "000000";
      inside-ver-color = "000000";
      inside-wrong-color = "000000";
      ring-color = "bec8d1";
      ring-ver-color = "137a7f";
      ring-wrong-color = "86cecb";
      ring-caps-lock-color = "e12885";
    };
  };
}
