{ config, pkgs, lib, ... }: let
  cfg = config.services.lisgd;
in {
  imports = [ ./home-manager.nix ./niri.nix ];

  options.services.lisgd = {
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
          "-g '1,LR,L,*,R,niri msg action focus-column-left' " +
          "-g '1,RL,R,*,R,niri msg action focus-column-right' " +
          "-g '1,UD,U,*,R,niri msg action focus-workspace-up' " +
          "-g '1,DU,D,*,R,niri msg action focus-workspace-down' " +
          "-g '2,LR,*,*,R,niri msg action focus-column-left' " +
          "-g '2,RL,*,*,R,niri msg action focus-column-right' " +
          "-g '2,UD,*,*,R,niri msg action focus-workspace-up' " +
          "-g '2,DU,*,*,R,niri msg action focus-workspace-down' " +
          "-g '2,LR,L,*,R,niri msg action move-column-right' " +
          "-g '2,RL,R,*,R,niri msg action move-column-left' " +
          "-g '2,UD,U,*,R,niri msg action move-column-to-workspace-up' " +
          "-g '2,DU,D,*,R,niri msg action move-column-to-workspace-down' " +
          "-g '3,LR,*,*,R,niri msg action move-column-right' " +
          "-g '3,RL,*,*,R,niri msg action move-column-left' " +
          "-g '3,UD,*,*,R,niri msg action move-column-to-workspace-up' " +
          "-g '3,DU,*,*,R,niri msg action move-column-to-workspace-down' " +
          #"-g '1,URDL,TR,*,R,foot' " +
          #"-g '1,ULDR,TL,*,R,firefox' " +
          #"-g '2,ULDR,TL,*,R,seekback-signal' " +
          #"-g '2,DU,D,*,R,niri msg action close-window' " +
          #"-g '1,UD,U,*,R,niri msg action screenshot' " +
          "";
      };
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
}
