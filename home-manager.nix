{
  config,
  lib,
  home-manager,
  specialArgs,
  ...
}:
{
  imports = [ home-manager.nixosModules.default ];

  options.kiyurica.home-manager.enable = lib.mkEnableOption "home-manager configuration";

  config = lib.mkIf config.kiyurica.home-manager.enable {
    home-manager.users.kiyurica = {
      imports = [ ./home-manager/base.nix ];
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        (final: prev: {
          python310Packages = specialArgs.nixpkgs-unstable.legacyPackages.${prev.system}.python310Packages;
        })
      ];
    };
    home-manager.extraSpecialArgs = specialArgs;
  };
}
