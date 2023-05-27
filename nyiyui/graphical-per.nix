{ config, pkgs, lib, ... }:
(lib.mkMerge [
  (lib.mkIf (config.home.file.hostname.text == "naha") {
    #nyiyui.swayidle.enable = false;
    wayland.windowManager.sway.config = {
      startup = [{
        command =
          "${pkgs.chromium}/bin/chromium '--proxy-server=socks5://10.42.0.1:1080' --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36'";
      }];
      output = {
        "eDP-1" = {
          pos = "0 0";
        };
        "HDMI-A-2" = {
          mode = "1920x1080@60.000Hz";
          pos = "1920 0";
        };
      };
    };
  })
  (lib.mkIf (config.home.file.hostname.text == "miyo") {
    wayland.windowManager.sway.config = {
      output = {
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
      input = {
        "1386:221:Wacom_Bamboo_Connect_Pen" = { map_to_output = "HDMI-A-1"; };
      };
    };
  })
  (lib.mkIf (config.home.file.hostname.text == "hananawi") {
    wayland.windowManager.sway.config = {
      output = {
        "eDP-1" = {
          mode = "2880x1800@60.001Hz";
          scale = "1.5";
          adaptive_sync = "on";
        };
      };
      input = {
        "1739:52914:SYNA8017:00_06CB:CEB2_Touchpad" = {
          events = "disabled";
        };
      };
    };
  })
])
