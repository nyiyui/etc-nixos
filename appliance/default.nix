{ pkgs, ... }:
{
  imports = [
    ./repart.nix
    ./sysupdate.nix
    ./sysupdate-notify.nix
    ./ephemeral-sysroot.nix
  ];

  environment.systemPackages = with pkgs; [
    # in case something goes wrong
    gptfdisk
    gparted
    # for signing UKIs
    sbctl
  ];
}
