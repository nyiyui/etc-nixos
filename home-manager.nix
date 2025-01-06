{ config, home-manager, ... }:
{
  imports = [ home-manager.nixosModule ];

  home-manager.users.nyiyui = {
    imports = [ ./home-manager/base.nix ];
    home.file.hostname.text = config.networking.hostName;
  };
}
