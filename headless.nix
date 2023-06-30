{ ... }:
{
  system.autoUpgrade.dates = "17:30";
  nic.gc.dates = "19:00";
  systemd.timers.autoupgrade-pull.timerConfig.OnCalendar = "17:00";
}
