# hjem user module: see ceka/auto-brightness.fish for the calibration table.
{
  pkgs,
  lib,
  ...
}:
let
  auto-brightness = pkgs.writeShellScriptBin "auto-brightness" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.brightnessctl
        pkgs.coreutils
      ]
    }:$PATH
    exec ${pkgs.fish}/bin/fish ${./auto-brightness.fish} "$@"
  '';
in
{
  packages = [ auto-brightness ];

  xdg.config.files."fish/conf.d/auto-brightness.fish".text = ''
    alias bl-auto='systemctl --user restart auto-brightness'
    alias bl-manual='systemctl --user stop auto-brightness'
  '';

  systemd.services.auto-brightness = {
    description = "Adjust the display backlight from the ambient light sensor";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    requires = [ "graphical-session.target" ];
    startLimitIntervalSec = 350;
    startLimitBurst = 30;
    serviceConfig = {
      ExecStart = "${auto-brightness}/bin/auto-brightness";
      Restart = "on-failure";
      RestartSec = 5;
      Nice = 10;
    };
    wantedBy = [ "graphical-session.target" ];
  };
}
