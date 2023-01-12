{ config, lib, pkgs, ... }:
{ 
  home.packages = with pkgs.libsForQt5; [
    qqc2-desktop-style
    qqc2-breeze-style
    breeze-qt5
    breeze-icons
  ];
}
