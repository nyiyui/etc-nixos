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

  networking.hostName = "rei";

  system.stateVersion = "23.05";

  environment.systemPackages = with pkgs; [ wireguard-tools ];

  qrystal.services.node.config.cs.azusa.networks.msb = {
    host = "rei.nyiyui.ca:39570";
  };
}
