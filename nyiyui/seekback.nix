{ pkgs, specialArgs, ... }:
let sockPath = "/home/nyiyui/.cache/seekback.sock";
in {
  systemd.user.services.seekback = {
    environment = { GOMAXPROCS = "1"; };
    Unit = {
      Description = "Seekback: replay audio from the past";
      StartLimitIntervalSec = 350;
      StartLimitBurst = 30;
    };
    Service = {
      ExecStart =
        "${specialArgs.seekback.packages.${pkgs.system}.default}/bin/seekback"
        + " -buffer-size 600000"
        + " -name '/home/nyiyui/inaba/seekback/%%s.aiff'"
        + " -latest-name /home/nyiyui/.cache/seekback-latest.aiff";
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
}
