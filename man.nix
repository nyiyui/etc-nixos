{ pkgs, ... }:
let
  qman = pkgs.callPackage ./pkgs/qman.nix { };
in
{
  environment.systemPackages = [
    pkgs.man-pages
    pkgs.man-pages-posix
    qman
  ];
  documentation.dev.enable = true;
  documentation.man.generateCaches = true;
}
