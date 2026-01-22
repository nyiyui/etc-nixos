{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.powertop-tune.enable = lib.mkEnableOption "Tuning commands from powertop(1)";
  options.powertop-tune.path = lib.mkOption {
    type = lib.types.path;
    description = "path to the script that powertop told you to run";
  };

  config = lib.mkIf config.powertop-tune.enable {
    systemd.services.powertop-tune = {
      description = "run powertop tunings";
      serviceConfig.ExecStart = "${pkgs.bash}/bin/sh ${config.powertop-tune.path}";
      serviceConfig.Type = "oneshot";
      wantedBy = [
        "multi-user.target"
      ];
    };
  };
}
