{ config, lib, pkgs, ... }:
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

    # Inhibit sleep while rebuilding so that the build is not interrupted.
    systemd.services.nixos-upgrade-sleep-inhibit = {
      description = "Sleep inhibitor for NixOS upgrade";
      before = [ "nixos-upgrade.service" ];
      wantedBy = [ "nixos-upgrade.service" ];
      partOf = [ "nixos-upgrade.service" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=sleep:idle --who=nixos-upgrade \"--why=upgrading the OS\" --mode=block ${pkgs.coreutils}/bin/sleep infinity";
        Restart = "no";
      };
    };
  };
}
