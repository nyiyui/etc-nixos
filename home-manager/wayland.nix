{ pkgs, ... }:
{
  imports = [ ./wlsunset.nix ];

  home.packages = with pkgs; [
    swaylock
    wl-clipboard
  ];
}
