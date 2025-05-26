{ pkgs, ... }:
{
  services.fprintd = {
    enable = true;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };
  security.pam.services.sudo.fprintAuth = true;
}
