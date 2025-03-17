{ config, pkgs, lib, ... }: let
  cfg = config.nyiyui.lisgd;
in {
  imports = [ ./home-manager.nix ];

  options.nyiyui.lisgd = {
    enable = lib.mkEnableOption "lisgd";
    touchscreenDeviceName = lib.mkOption {
      type = lib.types.str;
      description = "touchscreen device name to bind gestures on";
      example = "Wacom HID 511A Finger";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.nyiyui.extraGroups = [ "input" ]; # required for fusuma (see home-manager/touchscreen.nix)
    home-manager.users.nyiyui = { ... }: {
      systemd.user.services.lisgd = {
        Unit = {
          Description = "Libinput synthetic gesture daemon - Bind gestures on touchscreens, and unsupported gesture devices via libinput touch events";
          Documentation = [ "man:lisgd(1)" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service.ExecStart = pkgs.writeShellScript "lisgd.sh" ''
          device=$(${pkgs.libinput}/bin/libinput list-devices | /run/current-system/sw/bin/grep -A 1 '${cfg.touchscreenDeviceName}' | /run/current-system/sw/bin/grep /dev/input | /run/current-system/sw/bin/awk '{print $2}')
          ${pkgs.lisgd}/bin/lisgd -d "$device" -v -m 800 \
            -g '1,LR,L,*,*,swaymsg workspace prev' \
            -g '1,RL,R,*,*,swaymsg workspace next' \
            -g '1,UD,U,*,*,swaymsg kill' \
            -g '1,DU,D,*,*,systemctl --user restart wvkbd.service'
        '';
        Install.WantedBy = [ "graphical-session.target" ];
      };
      programs.waybar.settings.mainBar = {
        modules-left = [
          "custom/launch1"
          "custom/launch2"
        ];

        "custom/launch1" = {
          exec = "echo term";
          interval = "once";
          on-click = "foot";
        };
        "custom/launch2" = {
          exec = "echo ff";
          interval = "once";
          on-click = "firefox";
        };
      };
    };
  };
}
