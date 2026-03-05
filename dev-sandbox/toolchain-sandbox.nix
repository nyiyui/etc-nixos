{ config, lib, pkgs, ... }:
{
  imports = [ ../home-manager.nix ];

  config = lib.mkIf config.assr.dev-sandbox.enable {
    kiyurica.home-manager.enable = true;
    home-manager.users.kiyurica = { ... }: {
      programs.direnv = {
        enable = true;
        enableFishIntegration = true;
      };
    };
  };
}
