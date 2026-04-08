{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.assr.power-logger;
in
{
  options.assr.power-logger.enable = lib.mkEnableOption "system power and state logger";

  config = lib.mkIf cfg.enable {
    systemd.services.power-logger = {
      description = "Log battery, CPU, and GPU state";
      path = with pkgs; [
        linuxPackages.cpupower
        intel-gpu-tools
        pkgs.python3
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.python3}/bin/python3 ${./log_once.py}";
        # Ensure it can access sysfs and write to /var/lib/power-logger
        StateDirectory = "power-logger";
      };
    };

    systemd.timers.power-logger = {
      description = "Log battery, CPU, and GPU state every 5 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1m";
        OnUnitActiveSec = "5m";
        Persistent = true;
      };
    };
  };
}
