# Power Efficiency for x86 CPUs
# - x86_energy_perf_policy
# - manually take P-cores offline
# cf. https://wiki.archlinux.org/index.php?title=Power_management&oldid=842125#Power_saving
# latest = https://wiki.archlinux.org/wiki/Power_management
{ config, ... }:
{
  environment.systemPackages = [
    config.boot.kernelPackages.x86_energy_perf_policy
  ];
}
