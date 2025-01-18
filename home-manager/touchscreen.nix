{ pkgs, ... }:
{
  services.fusuma = {
    enable = true;
    extraPackages = [ pkgs.wtype ];
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
