# Advanced power efficiency module with charging detection
# Automatically enables aggressive power saving when on battery
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.kiyurica.power-efficiency;

  # Script to enable power saving mode
  enablePowerSaving = pkgs.writeShellScript "enable-power-saving" ''
    set -euo pipefail

    # Log the power state change
    ${pkgs.systemd}/bin/systemd-cat -t power-efficiency echo "Switching to battery power - enabling aggressive power saving"

    # Disable P-cores (performance cores) - typically cores 0-7 on modern Intel CPUs
    # This is aggressive but very effective for battery life
    for core in {0..7}; do
      if [ -f "/sys/devices/system/cpu/cpu$core/online" ]; then
        echo 0 > "/sys/devices/system/cpu/cpu$core/online" 2>/dev/null || true
      fi
    done

    # Set CPU energy performance preference to power (most aggressive)
    if command -v x86_energy_perf_policy >/dev/null 2>&1; then
      x86_energy_perf_policy power
    fi

    # Set CPU frequency scaling to powersave
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
      if [ -d "$policy" ]; then
        echo powersave > "$policy/scaling_governor" 2>/dev/null || true
      fi
    done

    # Reduce display brightness significantly
    if command -v light >/dev/null 2>&1; then
      light -S 20
    fi

    # Enable more aggressive Intel GPU power saving
    echo 1 > /sys/module/i915/parameters/enable_rc6 2>/dev/null || true
    echo 1 > /sys/module/i915/parameters/enable_fbc 2>/dev/null || true

    # Set PCI devices to powersave mode
    for pci in /sys/bus/pci/devices/*/power/control; do
      if [ -f "$pci" ]; then
        echo auto > "$pci" 2>/dev/null || true
      fi
    done

    # Set USB devices to autosuspend
    for usb in /sys/bus/usb/devices/*/power/control; do
      if [ -f "$usb" ]; then
        echo auto > "$usb" 2>/dev/null || true
      fi
    done

    # Reduce network card power
    for net in /sys/class/net/*/device/power/control; do
      if [ -f "$net" ]; then
        echo auto > "$net" 2>/dev/null || true
      fi
    done
  '';

  # Script to disable power saving mode (restore performance)
  disablePowerSaving = pkgs.writeShellScript "disable-power-saving" ''
    set -euo pipefail

    # Log the power state change
    ${pkgs.systemd}/bin/systemd-cat -t power-efficiency echo "AC power detected - restoring performance mode"

    # Re-enable P-cores
    for core in {0..7}; do
      if [ -f "/sys/devices/system/cpu/cpu$core/online" ]; then
        echo 1 > "/sys/devices/system/cpu/cpu$core/online" 2>/dev/null || true
      fi
    done

    # Set CPU energy performance preference to performance
    if command -v x86_energy_perf_policy >/dev/null 2>&1; then
      x86_energy_perf_policy performance
    fi

    # Set CPU frequency scaling to performance
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
      if [ -d "$policy" ]; then
        echo performance > "$policy/scaling_governor" 2>/dev/null || true
      fi
    done

    # Restore display brightness
    if command -v light >/dev/null 2>&1; then
      light -S 50
    fi

    # Set PCI devices back to on
    for pci in /sys/bus/pci/devices/*/power/control; do
      if [ -f "$pci" ]; then
        echo on > "$pci" 2>/dev/null || true
      fi
    done

    # Disable USB autosuspend for better responsiveness
    for usb in /sys/bus/usb/devices/*/power/control; do
      if [ -f "$usb" ]; then
        echo on > "$usb" 2>/dev/null || true
      fi
    done
  '';

in

{
  options.kiyurica.power-efficiency = {
    enable = mkEnableOption "advanced power efficiency with charging detection";

    aggressive = mkOption {
      type = types.bool;
      default = true;
      description = "Enable aggressive power saving including P-core disabling";
    };
  };

  config = mkIf cfg.enable {
    # Install required tools
    environment.systemPackages = with pkgs; [
      x86_energy_perf_policy
      light
      acpi
    ];

    # Enable MSR access for x86_energy_perf_policy
    boot.kernelModules = [ "msr" ];

    # Create systemd services for power state changes
    systemd.services.power-efficiency-battery = {
      description = "Enable aggressive power saving on battery";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${enablePowerSaving}";
        User = "root";
      };
    };

    systemd.services.power-efficiency-ac = {
      description = "Restore performance mode on AC power";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${disablePowerSaving}";
        User = "root";
      };
    };

    # udev rules to detect power supply changes
    services.udev.extraRules = ''
      # Detect AC adapter connection/disconnection
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl start power-efficiency-battery.service"
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl start power-efficiency-ac.service"

      # Also detect battery status changes as backup
      SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ATTR{status}=="Discharging", RUN+="${pkgs.systemd}/bin/systemctl start power-efficiency-battery.service"
      SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ATTR{status}=="Charging", RUN+="${pkgs.systemd}/bin/systemctl start power-efficiency-ac.service"
      SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ATTR{status}=="Full", RUN+="${pkgs.systemd}/bin/systemctl start power-efficiency-ac.service"
    '';

    # Set initial state based on current power status
    systemd.services.power-efficiency-init = {
      description = "Initialize power efficiency based on current power state";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "power-efficiency-init" ''
          # Check if AC power is connected
          if [ -f /sys/class/power_supply/ADP1/online ]; then
            if [ "$(cat /sys/class/power_supply/ADP1/online)" = "1" ]; then
              systemctl start power-efficiency-ac.service
            else
              systemctl start power-efficiency-battery.service
            fi
          elif [ -f /sys/class/power_supply/AC/online ]; then
            if [ "$(cat /sys/class/power_supply/AC/online)" = "1" ]; then
              systemctl start power-efficiency-ac.service
            else
              systemctl start power-efficiency-battery.service
            fi
          else
            # Fallback: assume battery power for safety
            systemctl start power-efficiency-battery.service
          fi
        '';
      };
    };

    # Allow users in wheel group to control brightness without sudo
    security.sudo.extraRules = [
      {
        users = [ "kiyurica" ];
        commands = [
          {
            command = "${pkgs.light}/bin/light";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
