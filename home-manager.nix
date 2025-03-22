{ config, home-manager, ... }:
{
  imports = [
    home-manager.nixosModule
    ({ config, lib, ... }: {
      config = lib.mkIf config.system.autoUpgrade.enable {
        home-manager.users.nyiyui = { ... }: {
          nyiyui.service-status = [
            { serviceName = "nixos-upgrade.service"; key = "↑"; }
          ];
        };
      };
    })
  ];

  home-manager.users.nyiyui = {
    imports = [ ./home-manager/base.nix ];
    home.file.hostname.text = config.networking.hostName;
  };
}
