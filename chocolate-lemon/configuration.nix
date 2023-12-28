{ config, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/google-compute-image.nix")
    ./kuromiya.nix
    ../kuromiya.nix
    ../base.nix
    ./cloudflare-ddns-update.nix
    ./hato.nix
  ];

  networking.hostName = "chocolate-lemon";

  system.stateVersion = "23.05";

  environment.systemPackages = with pkgs; [ wireguard-tools ];

  qrystal.services.node.config.cs.azusa.networks.msb = {
    host = "chocolate-lemon.nyiyui.ca:39570";
  };
  #miyamizu.services.target.enable = true;
  networking.firewall.enable = true; # enable firewall for fail2ban
}
