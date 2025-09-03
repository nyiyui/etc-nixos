{
  config,
  libs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.kiyurica;
in
{
  options.kiyurica.hasBacklight =
    with lib;
    with types;
    mkOption {
      type = bool;
      default = false;
      description = "enable backlight features";
    };
  options.kiyurica.service-status = lib.mkOption {
    type = (
      lib.types.listOf (
        lib.types.submodule {
          options = {
            serviceName = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "service name to show in waybar";
            };
            key = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "key to show in waybar";
            };
          };
        }
      )
    );
    default = [
      {
        serviceName = "nixos-upgrade.service";
        key = "u";
      }
    ];
    description = "show service status in waybar";
  };

  config = {
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
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
      settings =
        let
          genServiceStatus =
            { serviceName, key }:
            let
              script = pkgs.writeShellScriptBin "get-last-active-time.sh" ''
                export LOAD_ERROR="$(systemctl show ${serviceName} --property=LoadError | ${pkgs.coreutils}/bin/cut -d= -f2)"
                if [[ 0 != "$(echo -n "$LOAD_ERROR" | ${pkgs.coreutils}/bin/wc -w)" ]]; then
                  printf '{"text": "✕", "tooltip": %s, "class": "load-error"}' "$(echo -n "${serviceName}: $LOAD_ERROR" | ${pkgs.jq}/bin/jq -Rsa .)"
                fi
                export RESULT="$(systemctl show ${serviceName} --property=Result | ${pkgs.coreutils}/bin/cut -d= -f2)"
                export DATE="$(${pkgs.coreutils}/bin/date -d "$(systemctl show ${serviceName} --property=ActiveExitTimestamp | ${pkgs.coreutils}/bin/cut -d= -f2)" +'%m-%d %H')"
                if [[ "$RESULT" == "success" ]]; then
                  printf '{"text": "○${key}", "tooltip": "${serviceName} %s", "class": "success"}' "$DATE"
                else
                  printf '{"text": "△${key}", "tooltip": "${serviceName} %s: %s", "class": "%s"}' "$DATE" "$RESULT" "$RESULT"
                fi
              '';
            in
            {
              exec = "${script}/bin/get-last-active-time.sh";
              return-type = "json";
              interval = 60;
            };
        in
        {
          mainBar = {
            layer = "top";
            position = "bottom";
            height = 20;
            modules-right = [
              "tray"
              "network"
              "pulseaudio"
              "mpris"
            ]
            ++ (map (cfg: "custom/${cfg.key}") cfg.service-status)
            ++ [
              "battery"
              "clock"
            ];

            "battery" = {
              states.warning = 20;
              states.critical = 10;
              format = "{capacity} {time}";
              tooltip-format = "{power}W";
              format-time = "{H}:{m}";
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
              format-wifi = "{essid}{signaldBm}";
              format-disconnected = "";
              tooltip-format = "{ifname} {ipaddr} ; ↑{bandwidthUpOctets} ; ↓{bandwidthDownOctets}";
              tooltip-format-wifi = "{ifname} {essid} {signaldBm} dBm ; {frequency} GHz ; {ipaddr} ; ↑{bandwidthUpOctets} ; ↓{bandwidthDownOctets}";
              tooltip-format-disconnected = "切";
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
            "mpris" = {
              format = "{status_icon}{player_icon}{dynamic}";
              interval = 1;
              tooltip-format = "{title} ; 作{artist} ; ア{album} ; {position} / {length}";
              dynamic-len = 40;
              player-icons.firefox = "ff";
              player-icons.mpv = "mpv";
              status-icons.playing = "生";
              status-icons.paused = "停";
              status-icons.stopped = "止";
            };
            "custom/light" = lib.mkIf cfg.hasBacklight {
              exec = "${pkgs.light}/bin/light";
              interval = 10;
            };
          }
          // (builtins.foldl' (a: b: a // b) { } (
            map (cfg: {
              "custom/${cfg.key}" = genServiceStatus {
                serviceName = cfg.serviceName;
                key = cfg.key;
              };
            }) cfg.service-status
          ));
        };
    };

    services.mako = {
      enable = true;
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
      settings = {
        anchor = "bottom-right";
        font = "Roboto 12";
        background-color = "#000000c0";
        text-color = "#86cecb";
        height = 150;
        width = 600;
        icons = false;
        max-history = 65536;
        format = "<b>%s</b>\\n%b\\n%a %i";
        grouped = true;
        "grouped=true" = {
          format = "%g : %a <b>%s</b>\\n%b\\n%i";
        };
        "hidden=true" = {
          format = "%t / %h";
        };
        "urgency=low" = {
          border-size = 0;
        };
        "urgency=normal" = {
          border-color = "#cb86ce";
        };
        "urgency=critical" = {
          border-color = "#ffffff";
        };
      };
    };
    home.packages = with pkgs; [
      jq # required by mako for e.g. mako menu
    ];

    gtk.theme = {
      name = "Adwaita-dark";
    };

    programs.swaylock = {
      enable = true;
      settings = {
        ignore-empty-password = false; # e.g. PAM requires fingerprint, so make sure Enter key can trigger PAM
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
        indicator = true;
        image = "${../wallpapers/keikyu-signal.jpg}";
      };
    };
  };
}
