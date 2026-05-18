{ lib, pkgs, ... }:
{
  packages = [ pkgs.fuzzel ];
  xdg.config.files."fuzzel/fuzzel.ini" = {
    generator = lib.generators.toINI { };
    value = {
      main = {
        font = "Noto Sans:size=12";
      };
      colors = {
        background = "bec8d1cc";
        text = "137a7fff";
        match = "86cecbff";
        selection = "bec8d1ff";
        selection-text = "e12885ff";
        selection-match = "86cecbff";
      };
      border = {
        width = 0;
        radius = 0;
      };
    };
  };
}
