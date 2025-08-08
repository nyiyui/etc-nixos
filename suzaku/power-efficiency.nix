# Power Efficiency for x86 CPUs
# - x86_energy_perf_policy
# - manually take P-cores offline
# cf. https://wiki.archlinux.org/index.php?title=Power_management&oldid=842125#Power_saving
# latest = https://wiki.archlinux.org/wiki/Power_management
{ config, pkgs, ... }:
let
  pcoreScript = pkgs.writeShellScript "pcore-toggle" ''
    #!/usr/bin/env bash

    # Check for enable/disable argument
    action="disable"
    value=0
    if [[ $1 == "enable" ]]; then
        action="enable"
        value=1
    elif [[ $1 == "disable" ]]; then
        action="disable"
        value=0
    elif [[ -n $1 ]]; then
        echo "Usage: $0 [enable|disable]"
        echo "Default: disable"
        exit 1
    fi

    # Read P-cores from /sys/devices/cpu_core/cpus
    pcores=$(cat /sys/devices/cpu_core/cpus)

    # Parse the range and modify each P-core
    if [[ $pcores =~ ^([0-9]+)-([0-9]+)$ ]]; then
        start=''${BASH_REMATCH[1]}
        end=''${BASH_REMATCH[2]}
        
        for ((cpu=$start; cpu<=$end; cpu++)); do
            echo "''${action^}ing CPU $cpu"
            echo $value > /sys/devices/system/cpu/cpu$cpu/online
        done
    elif [[ $pcores =~ ^[0-9,]+$ ]]; then
        # Handle comma-separated list
        IFS=',' read -ra CPUS <<< "$pcores"
        for cpu in "''${CPUS[@]}"; do
            echo "''${action^}ing CPU $cpu"
            echo $value > /sys/devices/system/cpu/cpu$cpu/online
        done
    else
        echo "Unsupported format: $pcores"
        exit 1
    fi

    echo "P-cores ''${action}d"
  '';
in
{
  environment.systemPackages = [
    config.boot.kernelPackages.x86_energy_perf_policy
  ];

  # Udev rules to toggle P-cores based on power source
  services.udev.extraRules = ''
    # On AC power: enable P-cores
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pcoreScript} enable"
    # On battery power: disable P-cores  
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pcoreScript} disable"
  '';
}
