{ pkgs, ... }:
{
  services.fusuma = {
    enable = true;
    extraPackages = [
      pkgs.wtype
      pkgs.coreutils-full # uname is used by fusuma
    ];
    settings = {
      swipe."3" = {
        left = {
          command = "wtype -M Super l -m Super";
        };
        right = {
          command = "${pkgs.notify-desktop}/bin/notify-desktop 'right'";
        };
      };
    };
  };
}
