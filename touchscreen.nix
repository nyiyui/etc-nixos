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
        Service.ExecStart = "${pkgs.lisgd}/bin/lisgd -d ${cfg.touchscreenDevice} " +
          "-g '2,LR,*,*,R,niri msg action focus-column-left' " +
          "-g '2,RL,*,*,R,niri msg action focus-column-right' " +
          "-g '2,UD,*,*,R,niri msg action focus-workspace-up' " +
          "-g '2,DU,*,*,R,niri msg action focus-workspace-down' ";
      };
    };
  };
}
