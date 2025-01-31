{ config, pkgs, lib, ... }: {
  # does not work on shion and GT Library/Clough 3f ones
  options.nyiyui.displayLink.enable = lib.mkEnableOption "support for DisplayLink monitors, including GT Library docks";

  config = lib.mkIf config.nyiyui.displayLink.enable {
    services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
  };
}
