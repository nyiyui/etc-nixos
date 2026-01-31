{ config, lib, ... }:
{
  options.autoUpgrade.directFlake = lib.mkEnableOption "use Git flake URI directly";
  config = lib.mkIf config.autoUpgrade.directFlake {
    system.autoUpgrade = {
      enable = true;
      rebootWindow.lower = "01:00";
      rebootWindow.upper = "05:00";
      randomizedDelaySec = "1d";
      persistent = true;
      dates = lib.mkDefault "Fri 02:30";
      flake = "github:nyiyui/etc-nixos";
      allowReboot = true;
    };

    systemd.services.nixos-upgrade.unitConfig.ConditionACPower = true;
    # TODO: inhibit sleep while building
  };
}
