# Power Efficiency for x86 CPUs
# - x86_energy_perf_policy
# - manually take P-cores offline
# cf. https://wiki.archlinux.org/index.php?title=Power_management&oldid=842125#Power_saving
# latest = https://wiki.archlinux.org/wiki/Power_management
{ config, pkgs, ... }:
{
  environment.systemPackages = [
    config.boot.kernelPackages.x86_energy_perf_policy
  ];

  # Systemd services for CPU power management
  systemd.services.cpu-power-mode = {
    description = "Set CPU to power saving mode";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "cpu-power-mode" ''
        ${config.boot.kernelPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy power

        pcores=$(cat /sys/devices/cpu_core/cpus)

        if [[ $pcores =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start=''${BASH_REMATCH[1]}
            end=''${BASH_REMATCH[2]}
            
            for ((cpu=$start; cpu<=$end; cpu++)); do
                if [ $cpu -ne 0 ]; then
                    echo "Disabling CPU $cpu"
                    echo 0 > /sys/devices/system/cpu/cpu$cpu/online
                else
                    echo "Skipping CPU0 (never disable)"
                fi
            done
        elif [[ $pcores =~ ^[0-9,]+$ ]]; then
            IFS=',' read -ra CPUS <<< "$pcores"
            for cpu in "''${CPUS[@]}"; do
                if [ $cpu -ne 0 ]; then
                    echo "Disabling CPU $cpu"
                    echo 0 > /sys/devices/system/cpu/cpu$cpu/online
                else
                    echo "Skipping CPU0 (never disable)"
                fi
            done
        else
            echo "Unsupported format: $pcores"
            exit 1
        fi

        echo "CPU power mode enabled"
      '';
    };
  };

  systemd.services.cpu-performance-mode = {
    description = "Set CPU to performance mode";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "cpu-performance-mode" ''
        ${config.boot.kernelPackages.x86_energy_perf_policy}/bin/x86_energy_perf_policy performance

        for ((cpu=0; cpu<$(nproc --all); cpu++)); do
            if [ $cpu -ne 0 ]; then
                echo "Enabling CPU $cpu"
                echo 1 > /sys/devices/system/cpu/cpu$cpu/online
            else
                echo "Skipping CPU0"
            fi
        done

        echo "CPU performance mode enabled"
      '';
    };
  };

  # Udev rules to trigger systemd services based on power source
  services.udev.extraRules = ''
    # On AC power: enable performance mode
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.systemd}/bin/systemctl start cpu-performance-mode.service"
    # On battery power: enable power saving mode  
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.systemd}/bin/systemctl start cpu-power-mode.service"
  '';
}
