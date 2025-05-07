{ modulesPath, ... }:
{
  imports = [
    ./all-modules.nix
    "${modulesPath}/profiles/headless.nix"
    "${modulesPath}/profiles/minimal.nix"
  ];
  system.autoUpgrade.dates = "17:30";
  nix.gc.dates = "19:00";
  systemd.timers.autoupgrade-pull.timerConfig.OnCalendar = "17:00";
}
