# Support for DisplayLink devices.
# Tested on Dell Universal Dock D6000 on 2025-Jun-25
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kiyurica.displaylink.enable = lib.mkEnableOption "DisplayLink support";

  config = lib.mkIf config.kiyurica.displaylink.enable {
    boot = {
      extraModulePackages = [ config.boot.kernelPackages.evdi ];
      initrd.kernelModules = [ "evdi" ];
    };
    environment.systemPackages = with pkgs; [
      displaylink
    ];
    # service based on https://aur.archlinux.org/displaylink.git commit f44fffc53789cc64c92f3eb0e22022f5daba65b3
    systemd.services.displaylink-manager = {
      after = [ "display-manager.service" ];
      serviceConfig = {
        ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
        WorkingDirectory = "${pkgs.displaylink}/lib/displaylink";
        Restart = "always";
        RestartSec = 5;
      };
      wantedBy = [ "graphical.target" ];
    };
  };
}
