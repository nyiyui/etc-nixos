{ pkgs, ... }: {
  systemd.services.mitsuha = {
    enable = true;
    description = "set cpupower governor depending on battery state";
    wantedBy = [ "multi-user.target" ];
    unitConfig = {
      #StartLimitIntervalSec = 350;
      #StartLimitBurst = 30;
    };
    serviceConfig = {
      #Restart = "on-failure";
      #RestartSec = 3;
    };
    script = ''
      lastState=""
      while true; do
        curState="$(cat /sys/class/power_supply/AC/online)"
        if [[ "$curState" != "$lastState" ]]; then
          if [[ "$curState" == 0 ]]; then
            ${pkgs.cpupower}/bin/cpupower frequency-set -g powersave
          elif [[ "$curState" == 1 ]]; then
            ${pkgs.cpupower}/bin/cpupower frequency-set -g performance
          fi
        fi
        sleep 30
      done
    '';
  };
}
