{ config, lib, pkgs, ... }: {
  home.packages = with pkgs;
    with libsForQt5; [
      qqc2-desktop-style
      qqc2-breeze-style
      breeze-qt5
      breeze-icons

      kdenlive
      glaxnimate
      ffmpeg-full
      frei0r
      mediainfo
    ];
}
