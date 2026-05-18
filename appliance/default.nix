{ pkgs, ... }:
{
  imports = [
    ./repart.nix
    ./sysupdate.nix
    ./ephemeral-sysroot.nix
  ];

  environment.systemPackages = with pkgs; [
    gptfdisk
    gparted
  ];
}
