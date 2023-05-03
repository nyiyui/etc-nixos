{ config, lib, pkgs, ... }:

{
  systemd.user.services.safeeyes = {
    Unit = {
      Description =
        "Safe eyes: simple and beautiful, yet extensible break reminder";
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart = "${pkgs.safeeyes}/bin/safeeyes";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
