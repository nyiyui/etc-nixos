{ config, pkgs, lib, ... }:
(lib.mkMerge [
  (lib.mkIf (config.home.file.hostname.text == "hinanawi") {
    wayland.windowManager.sway.config = {
      input = {
        "1739:52914:SYNA8017:00_06CB:CEB2_Touchpad" = { events = "disabled"; };
      };
      output = {
        "eDP-1" = {
          mode = "2880x1800@60.001Hz";
          scale = "1.5";
          adaptive_sync = "on";
        };
      };
    };
  })
])
