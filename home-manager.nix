{
  config,
  home-manager,
  specialArgs,
  ...
}:
{
  imports = [ home-manager.nixosModule ];

  home-manager.users.kiyurica = {
    imports = [ ./home-manager/base.nix ];
  };
  home-manager.extraSpecialArgs = specialArgs;
}
