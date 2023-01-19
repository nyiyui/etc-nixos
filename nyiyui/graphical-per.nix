{ config, pkgs, lib, ... }:
(lib.mkMerge [
  (lib.mkIf (config.home.file.hostname.text == "kumi") {
    wayland.windowManager.sway.config.output = {
      "DP-1" = {
        mode = "3840x2160@60.000Hz";
        pos = "0 0";
        scale = "2";
      };
      "eDP-1".pos = "960 2160";
    };
  })
  (lib.mkIf (config.home.file.hostname.text == "miyo") {
    wayland.windowManager.sway.config.output = {
      "HDMI-A-1" = {
        mode = "3840x2160@30.000Hz";
        pos = "3840 0";
        scale = "1.25";
      };
      "HDMI-A-2" = {
        mode = "3840x2160@60.000Hz";
        pos = "0 0";
        scale = "1.5";
      };
    };
  })
])
