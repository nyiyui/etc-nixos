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
          "-g '1,LR,L,*,R,niri msg action focus-column-left' " +
          "-g '1,RL,R,*,R,niri msg action focus-column-right' " +
          "-g '1,UD,U,*,R,niri msg action focus-workspace-up' " +
          "-g '1,DU,D,*,R,niri msg action focus-workspace-down' ";
      };
    };
  };
}
