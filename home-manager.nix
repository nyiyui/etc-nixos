{ config, home-manager, ... }:
{
  imports = [ home-manager.nixosModule ];

  home-manager.users.kiyurica = {
    imports = [ ./home-manager/base.nix ];
  };
}
