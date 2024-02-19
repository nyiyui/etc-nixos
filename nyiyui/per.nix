{ config, pkgs, lib, ... }:
(lib.mkMerge [
  (lib.mkIf (config.home.file.hostname.text == "mitsu8") {
    services.wlsunset.temperature.night = 4000;
    wayland.windowManager.sway.config = {
      startup = [{
        command =
          "${pkgs.chromium}/bin/chromium '--proxy-server=socks5://10.42.0.1:1080' --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36'";
      }];
      output = {
        "HDMI-A-1" = {
          mode = "3840x2160@60.000Hz";
          pos = "0 0";
          scale = "2";
        };
      };
    };
  })
  (lib.mkIf (config.home.file.hostname.text == "naha") {
    #nyiyui.swayidle.enable = false;
    wayland.windowManager.sway.config = {
      startup = [{
        command =
          "${pkgs.chromium}/bin/chromium '--proxy-server=socks5://10.42.0.1:1080' --user-agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36'";
      }];
      output = {
        "eDP-1" = { pos = "0 1080"; };
        "HDMI-A-2" = {
          mode = "3840x2160@30.000Hz";
          pos = "0 0";
          scale = "2";
        };
      };
    };
  })
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
