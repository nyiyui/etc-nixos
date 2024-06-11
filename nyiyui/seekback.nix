{ pkgs, specialArgs, ... }:
let sockPath = "/home/nyiyui/.cache/seekback.sock";
in {
  systemd.user.services.seekback = {
    Unit = {
      Description = "Seekback: replay audio from the past";
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart = "${pkgs.coreutils-full}/bin/env GOMAXPROCS=1 ${
          specialArgs.seekback.packages.${pkgs.system}.default
        }/bin/seekback" + " -buffer-size 500000"
        + " -name '/home/nyiyui/inaba/seekback/%%s.aiff'"
        + " -latest-name /home/nyiyui/.cache/seekback-latest.aiff";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
  home.packages = [
    (pkgs.writeShellScriptBin "seekback-signal" ''
      ${pkgs.bash}/bin/bash ${../seekback-signal.sh}
    '')
  ];
}
