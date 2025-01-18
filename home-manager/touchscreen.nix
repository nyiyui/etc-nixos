{ config, pkgs, ... }:
{
  services.fusuma = {
    enable = true;
    extraPackages = [
      config.programs.niri.package
      pkgs.coreutils-full # uname is used by fusuma
    ];
    settings = {
      swipe."3" = {
        left = {
          command = "niri msg action focus-column-left";
        };
        right = {
          command = "${pkgs.notify-desktop}/bin/notify-desktop 'right'";
        };
      };
    };
  };
}
