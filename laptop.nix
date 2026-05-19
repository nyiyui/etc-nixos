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
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${config.boot.kernelPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy power"
        SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${config.boot.kernelPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy performance"
      '';
      #      services.tlp.enable = true;
      services.tlp.settings = {
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_SCALING_GOVERNOR_ON_AC = "performance";

        # The following prevents the battery from charging fully to
        # preserve lifetime. Run `tlp fullcharge` to temporarily force
        # full charge.
        # https://linrunner.de/tlp/faq/battery.html#how-to-choose-good-battery-charge-thresholds
        # https://support.lenovo.com/jp/ja/solutions/ht078208-how-can-i-increase-battery-life-thinkpad-and-lenovo-vbke-series-notebooks
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;

        # 100 being the maximum, limit the speed of my CPU to reduce
        # heat and increase battery usage:
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MAX_PERF_ON_BAT = 30;
      };
    };
}
