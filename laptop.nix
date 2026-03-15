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
      services.logind.settings.Login.HandleLidSwitchDocked = "ignore";
      networking.networkmanager.wifi.powersave = true;
      services.udev.extraRules = ''
        # Power adapter connected/disconnected detection
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${config.boot.kernelPackages.x86_energy_perf_policy} power"
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${config.boot.kernelPackages.x86_energy_perf_policy} performance"
      '';
    };
}
