{ pkgs, ... }:
{
  imports = [
    ./repart.nix
    ./sysupdate.nix
    ./update-notification.nix
  ];

  environment.systemPackages = with pkgs; [
    gptfdisk
    gparted
  ];
}
