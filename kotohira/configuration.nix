{ pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/google-compute-image.nix")
    ../autoUpgrade.nix
    ./kuromiya.nix
    ../kuromiya.nix
    ../base.nix
    ../headless.nix
  ];

  networking.hostName = "kotohira";

  system.stateVersion = "23.05";

  environment.systemPackages = with pkgs; [ wireguard-tools ];

  qrystal.services.node.config.cs.azusa.networks.msb = {
    host = "kotohira.nyiyui.ca:39570";
  };
}
