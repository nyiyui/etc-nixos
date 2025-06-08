{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.kiyurica.laptop.enable = lib.mkEnableOption "convenience functions for laptops";
  options.kiyurica.laptop.builtinDisplay = lib.mkOption {
    description = "Built-in display name";
    default = "eDP-1";
  };
  config =
    let
      builtinDisplay = config.kiyurica.laptop.builtinDisplay;
    in
    lib.mkIf config.kiyurica.laptop.enable {
      home-manager.users.kiyurica =
        { config, lib, ... }:
        {
          config = lib.mkIf config.wayland.windowManager.sway.enable {
            wayland.windowManager.sway.extraConfig = ''
              bindswitch lid:on  output ${builtinDisplay} disable
              bindswitch lid:off output ${builtinDisplay} enable
            '';
          };
        };
      services.logind.lidSwitchDocked = "ignore";
    };
}
