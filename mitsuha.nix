{ pkgs, ... }:
{
  systemd.services.mitsuha = {
    enable = true;
    description = "set cpupower governor depending on battery state";
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      #StartLimitIntervalSec = 350;
      #StartLimitBurst = 30;
    };
    environment = {
      CPUPOWER = "${pkgs.cpupower}/bin/cpupower";
    };
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash " + ./mitsuha.sh;
      #Restart = "on-failure";
      #RestartSec = 3;
    };
  };
}
