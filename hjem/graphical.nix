{
  config,
  libs,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.kiyurica;

  debugEnvScript = pkgs.writeShellScriptBin "debug-autostart-env" ''
    echo "--- $(date) ---" >> /tmp/autostart-env.log
    env | sort >> /tmp/autostart-env.log
    echo "--- DBUS_SESSION_BUS_ADDRESS: $DBUS_SESSION_BUS_ADDRESS ---" >> /tmp/autostart-env.log
  '';
  debugEnvDesktop = pkgs.writeTextDir "share/applications/debug-autostart-env.desktop" ''
    [Desktop Entry]
    Type=Application
    Name=Debug Autostart Env
    Exec=${debugEnvScript}/bin/debug-autostart-env
    NoDisplay=true
  '';
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
            propertyName = lib.mkOption {
              type = lib.types.str;
              default = "Result";
              description = "systemd service property to compare";
            };
            user = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Use systemd --user (session bus)";
            };
            propertyValue = lib.mkOption {
              type = lib.types.str;
              default = "success";
              description = "systemd service property value where equal = success";
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
  options.kiyurica.icsUrlPath =
    with lib;
    with types;
    mkOption {
      type = nullOr str;
      default = null;
      description = "waybar: path to ICS URL for the next event module";
    };
  options.kiyurica.waybarPosition =
    with lib;
    with types;
    mkOption {
      type = enum [
        "top"
        "bottom"
        "left"
        "right"
      ];
      default = "bottom";
      description = "waybar: position on screen (top, bottom, left, or right)";
    };

  options.kiyurica.graphical.backgroundImage =
    with lib;
    with types;
    mkOption {
      type = path;
      default = ../wallpapers/arima-onsen.jpg;
      description = "Path to the background/wallpaper image file";
    };

  options.kiyurica.graphical.idle = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Sleep, lock, etc on idle";
  };

  config = {
    packages = with pkgs; [
      waybar
      mako
      swaylock
      zathura
      jq
      pavucontrol
    ];

    xdg.config.files."waybar/style.css".text = builtins.readFile ./waybar.css;
    xdg.config.files."waybar/config" = {
      generator = lib.generators.toJSON { };
      value =
        let
          isVertical = cfg.waybarPosition == "left" || cfg.waybarPosition == "right";
          rotationAngle = if isVertical then 270 else 0;
          genServiceStatus =
            {
              serviceName,
              key,
              propertyName,
              propertyValue,
              user ? false,
            }:
            let
              escapedServiceName = builtins.replaceStrings [ "." "-" ] [ "_2e" "_2d" ] serviceName;
              script = pkgs.writeShellScriptBin "monitor-service-status.sh" ''
                SYSTEMCTL="systemctl${lib.optionalString user " --user"}"
                DBUS_MONITOR="${pkgs.dbus}/bin/dbus-monitor${lib.optionalString user " --session"}${
                  lib.optionalString (!user) " --system"
                }"

                get_status() {
                  export LOAD_ERROR="$($SYSTEMCTL show ${serviceName} --property=LoadError | ${pkgs.coreutils}/bin/cut -d= -f2)"
                  if [[ 0 != "$(echo -n "$LOAD_ERROR" | ${pkgs.coreutils}/bin/wc -w)" ]]; then
                    printf '{"text": "✕", "tooltip": %s, "class": "load-error"}' "$(echo -n "${serviceName}: $LOAD_ERROR" | ${pkgs.jq}/bin/jq -Rsa .)"
                    return
                  fi
                  export RESULT="$($SYSTEMCTL show ${serviceName} --property=${propertyName} | ${pkgs.coreutils}/bin/cut -d= -f2)"
                  export DATE="$(${pkgs.coreutils}/bin/date -d "$( $SYSTEMCTL show ${serviceName} --property=ActiveExitTimestamp | ${pkgs.coreutils}/bin/cut -d= -f2)" +'%m-%d %H')"
                  if [[ "$RESULT" == "${propertyValue}" ]]; then
                    printf '{"text": "○${key}", "tooltip": "${serviceName} %s", "class": "success"}\n' "$DATE"
                  else
                    printf '{"text": "△${key}", "tooltip": "${serviceName} %s: %s", "class": "%s"}\n' "$DATE" "$RESULT" "$RESULT"
                  fi
                }

                # Print initial status
                get_status

                # Monitor for changes
                $DBUS_MONITOR \
                  "type='signal',sender='org.freedesktop.systemd1',path='/org/freedesktop/systemd1/unit/${escapedServiceName}',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" \
                  | while read -r line; do
                    get_status
                  done

              '';
            in
            {
              exec = "${script}/bin/monitor-service-status.sh";
              return-type = "json";
              rotate = rotationAngle;
            };
        in
        {
          layer = "top";
          position = cfg.waybarPosition;
          height = if !isVertical then 20 else null;
          width = if isVertical then 20 else null;
          modules-right =
            (if cfg.icsUrlPath != null then [ "custom/next-event" ] else [ ])
            ++ [
              "tray"
              "network"
              "wireplumber"
              "mpris"
            ]
            ++ (map (cfg: "custom/${cfg.key}") cfg.service-status)
            ++ [
              "battery"
              "clock"
            ];

          "battery" = {
            states = {
              warning = 20;
              critical = 10;
            };
            format = "{capacity} {time}";
            tooltip-format = "{power}W";
            format-time = "{H}:{m}";
            rotate = rotationAngle;
          };
          "clock" = {
            format = "{:%H:%M %Y-%m-%d}";
            tooltip-format = "{calendar}";
            rotate = rotationAngle;
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
            rotate = rotationAngle;
          };
          "wireplumber" = {
            format = "{volume}";
            on-click = "pwvucontrol";
          };
          "mpris" = {
            format = "{status_icon}{player_icon}{dynamic}";
            interval = 1;
            tooltip-format = "{title} ; 作{artist} ; ア{album} ; {position} / {length}";
            dynamic-len = 40;
            player-icons = {
              firefox = "ff";
              mpv = "mpv";
            };
            status-icons = {
              playing = "生";
              paused = "停";
              stopped = "止";
            };
            rotate = rotationAngle;
          };
          "custom/light" =
            if cfg.hasBacklight then
              {
                exec = "${pkgs.light}/bin/light";
                interval = 10;
                rotate = rotationAngle;
              }
            else
              null;

          "custom/next-event" =
            if cfg.icsUrlPath != null then
              {
                exec = "${
                  pkgs.python3.withPackages (
                    ps: with ps; [
                      requests
                      icalendar
                      recurring-ical-events
                    ]
                  )
                }/bin/python ${./ics_next_event.py} '${cfg.icsUrlPath}'";
                return-type = "json";
                interval = 60;
                rotate = rotationAngle;
              }
            else
              null;
        }
        // (builtins.foldl' (a: b: a // b) { } (
          map (cfg: {
            "custom/${cfg.key}" = genServiceStatus {
              serviceName = cfg.serviceName;
              key = cfg.key;
              propertyName = cfg.propertyName;
              propertyValue = cfg.propertyValue;
            };
          }) cfg.service-status
        ));
    };

    systemd.services.waybar = {
      description = "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
      documentation = [ "https://github.com/alexays/waybar/wiki" ];
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.waybar}/bin/waybar";
        ExecReload = "kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
      };
    };

    xdg.config.files."mako/config".text = ''
      anchor=bottom-right
      font=Roboto 12
      background-color=#000000c0
      text-color=#86cecb
      height=150
      width=600
      icons=0
      max-history=65536
      format=<b>%s</b>\n%b\n%a %i

      [grouped]
      format=%g : %a <b>%s</b>\n%b\n%i

      [hidden]
      format=%t / %h

      [urgency=low]
      border-size=0

      [urgency=normal]
      border-color=#cb86ce

      [urgency=critical]
      border-color=#ffffff
    '';

    xdg.config.files."swaylock/config".text = ''
      show-failed-attempts
      show-keyboard-layout
      color=000000
      inside-color=000000
      inside-clear-color=000000
      inside-caps-lock-color=000000
      inside-ver-color=000000
      inside-wrong-color=000000
      ring-color=bec8d1
      ring-ver-color=137a7f
      ring-wrong-color=86cecb
      ring-caps-lock-color=e12885
      image=${../wallpapers/shibuya-gmo.jpg}
    '';

    xdg.config.files."zathura/zathurarc".text = ''
      set selection-clipboard clipboard
    '';

    xdg.config.files."systemd/user/app-firefox@autostart.service.d/pipewire.conf".text = ''
      [Unit]
      After=pipewire.service wireplumber.service pipewire-pulse.service
      Wants=pipewire-pulse.service
    '';

    files.".config/autostart/firefox.desktop".source =
      "/run/current-system/sw/share/applications/firefox.desktop";
    files.".config/autostart/signal.desktop".source =
      "/run/current-system/sw/share/applications/signal.desktop";
    files.".config/autostart/thunderbird.desktop".source =
      "/run/current-system/sw/share/applications/thunderbird.desktop";
    files.".config/autostart/io.github.alainm23.planify.desktop".source =
      "/run/current-system/sw/share/applications/io.github.alainm23.planify.desktop";
    files.".config/autostart/debug-autostart-env.desktop".source =
      "${debugEnvDesktop}/share/applications/debug-autostart-env.desktop";

    files.".gtkrc-2.0".text = ''
      gtk-im-module="fcitx"
      gtk-theme-name="Adwaita-dark"
    '';

    xdg.config.files."gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-im-module=fcitx
      gtk-theme-name=Adwaita-dark
      gtk-application-prefer-dark-theme=1
    '';

    xdg.config.files."gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-im-module=fcitx
      gtk-theme-name=Adwaita-dark
      gtk-application-prefer-dark-theme=1
    '';

    xdg.mime-apps = {
      default-applications = {
        "application/pdf" = "org.pwmt.zathura.desktop";
      };
    };

    systemd.services.swayidle = lib.mkIf config.kiyurica.graphical.idle {
      description = "swaywm: sleep, lock, etc on idle";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      requires = [ "graphical-session.target" ];
      startLimitIntervalSec = 350;
      startLimitBurst = 30;
      serviceConfig = {
        ExecStart = ''
          ${pkgs.swayidle}/bin/swayidle -w timeout 3600 'systemctl suspend'
        '';
        Restart = "on-failure";
        RestartSec = 3;
      };
      wantedBy = [ "graphical-session.target" ];
    };
  };
}
