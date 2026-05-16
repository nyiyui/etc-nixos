{ pkgs, ... }:
{
  imports = [
    ./repart.nix
    ./sysupdate.nix
    ./update-notification.nix
    ./ephemeral-sysroot.nix
  ];

  environment.systemPackages = with pkgs; [
    gptfdisk
    gparted
  ];
}
