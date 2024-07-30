{
  config,
  libs,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./fuzzel.nix ];

  wayland.windowManager.sway =
    let
      modifier = "Mod4";
    in
    {
      enable = true;
      extraConfig = ''
        default_border none
        default_floating_border none
        mode passthrough {
          bindsym ${modifier}+Home mode default
        }
        bindsym ${modifier}+Home mode passthrough
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
        inherit modifier;
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
          { command = "${pkgs.foot}/bin/foot ssh-add $(ls -1 ~/.ssh/id_* | grep -v '\\.pub$')"; }
        ];
        keybindings = lib.mkOptionDefault {
          # use wev to find pressed keys
          "XF86AudioPlay" = "exec playerctl play-pause";
          "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +1%";
          "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -1%";
          "Control+grave" = "exec playerctl play-pause";
          # Screenshots 
          "Print" = "exec ${pkgs.grim}/bin/grim - | tee ~/.cache/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy";
          "Shift+Print" = ''exec ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | tee ~/.cache/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy'';
          "${modifier}+Print" = ''exec ${pkgs.grim}/bin/grim -g "$(swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | tee ~/.cache/screenshot.png | ${pkgs.wl-clipboard}/bin/wl-copy'';
          "XF86MonBrightnessUp" = "exec light -A 1";
          "XF86MonBrightnessDown" = ''exec fish --command='if [ "$(light)" -le 1 ]; then; light -S 1; else; light -U 1; end' '';
          "${modifier}+Alt+L" = "exec swaylock";
          "${modifier}+Shift+Return" = "exec firefox";
          "${modifier}+Alt+Shift+Return" = "exec chromium";
          "${modifier}+Return" = "exec foot";
          "${modifier}+Alt+Return" = "exec ${pkgs.rnote}/bin/rnote";
          "${modifier}+Alt+N" = "exec ${pkgs.mako}/bin/makoctl menu 'fuzzel -d' -p '通知'";
          "${modifier}+N" = "exec ${pkgs.mako}/bin/makoctl dismiss";
          "${modifier}+Shift+N" = "exec ${pkgs.mako}/bin/makoctl restore";
          "${modifier}+Shift+S" = "exec bash ${../seekback-signal.sh}";
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

  programs.waybar.settings.mainBar = {
    modules-left = [ "sway/worksapces" "sway/window" ];

    "sway/workspaces" = {
      disable-scroll = true;
      all-outputs = true;
    };
    "sway/window" = {
      format = "{app_id} {title}";
      icon = true;
    };
  };
}
