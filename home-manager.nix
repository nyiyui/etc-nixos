{
  config,
  home-manager,
  specialArgs,
  ...
}:
{
  imports = [ home-manager.nixosModules.default ];

  home-manager.users.kiyurica = {
    imports = [ ./home-manager/base.nix ];
    nixpkgs.overlays = [
      (final: prev: {
        python310Packages = specialArgs.nixpkgs-unstable.legacyPackages.${prev.system}.python310Packages;
      })
    ];
  };
  home-manager.extraSpecialArgs = specialArgs;
}
