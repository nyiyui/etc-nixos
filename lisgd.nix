{ config, pkgs, lib, ... }: let
  cfg = config.nyiyui.lisgd;
in {
  imports = [ ./home-manager.nix ./niri.nix ];

  options.nyiyui.lisgd = {
    enable = lib.mkEnableOption "lisgd";
    touchscreenDevice = lib.mkOption {
      type = lib.types.path;
      description = "touchscreen device to bind gestures on";
      example = "/dev/input/event13";
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
        Service.ExecStart = "${pkgs.lisgd}/bin/lisgd -d ${cfg.touchscreenDevice} -v -m 800 " +
          "-g '1,LR,L,*,*,swaymsg workspace prev' " +
          "-g '1,RL,R,*,*,swaymsg workspace next' " +
          "";
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
