# Advanced power efficiency module with udev-based charging detection
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kiyurica.power-efficiency;

  # Script to apply power saving settings when on battery
  batteryPowerScript = pkgs.writeShellScript "battery-power" ''
    ${config.boot.kernelPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy powersave
    echo powersave > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
    echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
    echo 1500 > /proc/sys/vm/dirty_writeback_centisecs
  '';

  # Script to apply performance settings when on AC power
  acPowerScript = pkgs.writeShellScript "ac-power" ''
    ${config.boot.kernelPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy performance
    echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
    echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
    echo 500 > /proc/sys/vm/dirty_writeback_centisecs
  '';

in
{
  options.kiyurica.power-efficiency = {
    enable = mkEnableOption "automatic power efficiency management";
  };

  config = mkIf cfg.enable {
    # Install required packages
    environment.systemPackages = [
      config.boot.kernelPackages.x86_energy_perf_policy
    ];

    # Create udev rules for power adapter detection
    services.udev.extraRules = ''
      # Power adapter connected/disconnected detection
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${batteryPowerScript}"
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${acPowerScript}"

      # Alternative rule for ADP1 (common power adapter name)
      KERNEL=="ADP1", ATTR{online}=="0", RUN+="${batteryPowerScript}"
      KERNEL=="ADP1", ATTR{online}=="1", RUN+="${acPowerScript}"
    '';

    # Create systemd service to apply initial power settings
    systemd.services.power-efficiency-init = {
      description = "Initialize power efficiency settings";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "power-efficiency-init" ''
          # Check if we're on battery or AC power
          if [ -f /sys/class/power_supply/ADP1/online ]; then
            if [ "$(cat /sys/class/power_supply/ADP1/online)" = "1" ]; then
              ${acPowerScript}
            else
              ${batteryPowerScript}
            fi
          elif [ -f /sys/class/power_supply/AC/online ]; then
            if [ "$(cat /sys/class/power_supply/AC/online)" = "1" ]; then
              ${acPowerScript}
            else
              ${batteryPowerScript}
            fi
          else
            # Default to battery power settings if adapter state is unknown
            ${batteryPowerScript}
          fi
        '';
      };
    };

    # Ensure CPU frequency scaling is available
    boot.kernelModules = [
      "cpufreq_powersave"
      "cpufreq_performance"
    ];

    # Enable CPU frequency scaling
    powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  };
}
