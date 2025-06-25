{ config, lib, pkgs, ... }:
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
  };
}
