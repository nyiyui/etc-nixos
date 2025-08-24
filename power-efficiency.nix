{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.power-efficiency;
  
  # Script to determine if the laptop is charging
  isChargingScript = pkgs.writeShellScript "is-charging" ''
    # Check if any power supply is connected and charging
    for ps in /sys/class/power_supply/A{C,DP}*; do
      if [[ -f "$ps/online" ]] && [[ "$(cat "$ps/online")" == "1" ]]; then
        exit 0  # Charging
      fi
    done
    exit 1  # Not charging
  '';
  
  # Script to disable P-cores (except core 0 which cannot be disabled)
  disablePCoresScript = pkgs.writeShellScript "disable-p-cores" ''
    if [[ -f /sys/devices/system/cpu/cpu_core/cpus ]]; then
      p_cores=$(cat /sys/devices/system/cpu/cpu_core/cpus)
      echo "P-cores detected: $p_cores" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
      
      # Parse the range and disable each P-core except core 0
      IFS=',' read -ra RANGES <<< "$p_cores"
      for range in "''${RANGES[@]}"; do
        if [[ "$range" == *-* ]]; then
          # Handle range format like "0-7"
          start=$(echo "$range" | cut -d'-' -f1)
          end=$(echo "$range" | cut -d'-' -f2)
          for ((i=start; i<=end; i++)); do
            if [[ $i -ne 0 ]] && [[ -f "/sys/devices/system/cpu/cpu$i/online" ]]; then
              echo 0 > "/sys/devices/system/cpu/cpu$i/online" 2>/dev/null || true
              echo "Disabled CPU core $i" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
            fi
          done
        else
          # Handle single core
          if [[ "$range" -ne 0 ]] && [[ -f "/sys/devices/system/cpu/cpu$range/online" ]]; then
            echo 0 > "/sys/devices/system/cpu/cpu$range/online" 2>/dev/null || true
            echo "Disabled CPU core $range" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
          fi
        fi
      done
    else
      echo "P-core information not available" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
    fi
  '';
  
  # Script to enable all P-cores
  enablePCoresScript = pkgs.writeShellScript "enable-p-cores" ''
    if [[ -f /sys/devices/system/cpu/cpu_core/cpus ]]; then
      p_cores=$(cat /sys/devices/system/cpu/cpu_core/cpus)
      echo "Re-enabling P-cores: $p_cores" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
      
      # Parse the range and enable each P-core
      IFS=',' read -ra RANGES <<< "$p_cores"
      for range in "''${RANGES[@]}"; do
        if [[ "$range" == *-* ]]; then
          # Handle range format like "0-7"
          start=$(echo "$range" | cut -d'-' -f1)
          end=$(echo "$range" | cut -d'-' -f2)
          for ((i=start; i<=end; i++)); do
            if [[ -f "/sys/devices/system/cpu/cpu$i/online" ]]; then
              echo 1 > "/sys/devices/system/cpu/cpu$i/online" 2>/dev/null || true
              echo "Enabled CPU core $i" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
            fi
          done
        else
          # Handle single core
          if [[ -f "/sys/devices/system/cpu/cpu$range/online" ]]; then
            echo 1 > "/sys/devices/system/cpu/cpu$range/online" 2>/dev/null || true
            echo "Enabled CPU core $range" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
          fi
        fi
      done
    else
      echo "P-core information not available" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
    fi
  '';
  
  # Main power efficiency management script
  powerEfficiencyScript = pkgs.writeShellScript "power-efficiency-manager" ''
    if ${isChargingScript}; then
      echo "Power adapter connected - enabling performance mode" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
      
      # Enable all P-cores
      ${enablePCoresScript}
      
      # Set energy performance preference to performance
      if command -v ${pkgs.linuxPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy >/dev/null 2>&1; then
        ${pkgs.linuxPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy performance 2>/dev/null || true
        echo "Set energy performance policy to performance" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
      fi
      
      # Set CPU governor to performance via cpufreq
      for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$cpu" ]]; then
          echo performance > "$cpu" 2>/dev/null || true
        fi
      done
      echo "Set CPU scaling governor to performance" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
      
    else
      echo "Running on battery - enabling power saving mode" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
      
      # Disable P-cores (except core 0)
      ${disablePCoresScript}
      
      # Set energy performance preference to power saving
      if command -v ${pkgs.linuxPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy >/dev/null 2>&1; then
        ${pkgs.linuxPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy powersave 2>/dev/null || true
        echo "Set energy performance policy to powersave" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
      fi
      
      # Set CPU governor to powersave
      for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [[ -f "$cpu" ]]; then
          echo powersave > "$cpu" 2>/dev/null || true
        fi
      done
      echo "Set CPU scaling governor to powersave" | ${pkgs.systemd}/bin/systemd-cat -t power-efficiency
    fi
  '';

in {
  options.services.power-efficiency = {
    enable = mkEnableOption "automatic power efficiency management based on charging status";
  };

  config = mkIf cfg.enable {
    # Install x86_energy_perf_policy
    environment.systemPackages = with pkgs; [
      linuxPackages.x86_energy_perf_policy
    ];

    # udev rules to detect power supply changes
    services.udev.extraRules = ''
      # Trigger power efficiency script when power supply status changes
      SUBSYSTEM=="power_supply", KERNEL=="ADP*|AC*", ATTR{online}=="0", RUN+="${powerEfficiencyScript}"
      SUBSYSTEM=="power_supply", KERNEL=="ADP*|AC*", ATTR{online}=="1", RUN+="${powerEfficiencyScript}"
    '';

    # systemd service to run power efficiency script on boot
    systemd.services.power-efficiency-init = {
      description = "Initialize power efficiency settings based on current charging status";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = powerEfficiencyScript;
        RemainAfterExit = false;
        # Run with elevated privileges to modify CPU settings
        User = "root";
      };
    };
  };
}