{ config, libs, pkgs, lib, ... }:

{
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-hangul
      fcitx5-gtk
    ];
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
        modules-right = [ "tray" "network" "temperature" "pulseaudio" "battery" "clock" ];
    
        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };
        "clock" = {
          format = "{:%H:%M %Y-%m-%d}";
        };
        "network" = {
          format = "{ifname}";
          format-wifi = "{essid} {signaldBm}";
          format-disconnected = "";
          on-click = "${pkgs.foot}/bin/foot ~/wifi_conn_new";
          tooltip-format = "{ifname} {ipaddr} {bandwidthUpOctets} {bandwidthUpOctets}";
          tooltip-format-wifi = "{ifname} {essid} {signaldBm} dBm {frequency} MHz {ipaddr} {bandwidthUpOctets} {bandwidthUpOctets}";
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
        { command = "systemctl --user restart waybar"; always = true; }
        { command = "systemctl --user restart wlsunset"; always = true; }
        { command = "${pkgs.chromium}/bin/chromium"; }
        { command = "${pkgs.foot}/bin/foot ssh-add $(ls -1 ~/.ssh/id_* | grep -v '\\.pub$')"; }
      ];
      keybindings = lib.mkOptionDefault {
        # use wev to find pressed keys
        "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
        "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +1%";
        "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -1%";
        "XF86AudioPlay" = "exec playerctl play-pause";
        # Screenshots 
        "Print" = "exec grim - | tee ~/.cache/screenshot.png | wl-copy";
        "Shift+Print" = ''exec grim -g "$(slurp)" - | tee ~/.cache/screenshot.png | wl-copy'';
        "${modifier}+Print" = ''exec grim -g "$(swaymsg -t get_tree | jq -r '.. | select(.focused?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | tee ~/.cache/screenshot.png | wl-copy'';
        "XF86MonBrightnessUp" = "exec light -A 1";
        "XF86MonBrightnessDown" = "exec light -U 1";
        "${modifier}+Shift+Return" = "exec chromium";
        "${modifier}+Return" = "exec foot";
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
        ];
      };
      bars = [];
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
      format=%a <b>%s</b>\n%b\n%i
      [grouped=true]
      format=%g / %a <b>%s</b>\n%b\n%i
      [hidden=true]
      format=%tの内%h
      [urgency=low]
      border-size=0

      [urgency=normal]
      border-color=#cb86ce

      [urgency=critical]
      border-color=#ffffff
    '';
  };
}
