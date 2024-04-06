{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.man-pages pkgs.man-pages-posix ];
  documentation.dev.enable = true;
  documentation.man.generateCaches = true;
}
