{
  pkgs,
  config,
  specialArgs,
  ...
}:
{
  imports = [ ./home-manager.nix ];

  kiyurica.home-manager.enable = true;

  nixpkgs.overlays = [
    (final: prev: {
      github-copilot-cli =
        (import specialArgs.nixpkgs-unstable {
          inherit (prev) system;
          config.allowUnfree = true;
        }).github-copilot-cli;
    })
  ];
  environment.systemPackages = [
    pkgs.github-copilot-cli
  ];

  home-manager.users.kiyurica =
    let
      systemconfig = config;
    in
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          codex = specialArgs.nixpkgs-unstable.legacyPackages.${prev.system}.codex;
        })
      ];
      home.packages = with pkgs; [
        codex
      ];
    };
}
