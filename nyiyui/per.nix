{ config, pkgs, lib, ... }:
(lib.mkMerge [
  (lib.mkIf (config.home.file.hostname.text == "miyo") {
    programs.foot.settings.main.font = "hack:size=12";
  })
  (lib.mkIf (config.home.file.hostname.text == "naha") {
    programs.chromium = {
      enable = true;
      commandLineArgs = [
        "--proxy-server=socks5://10.42.0.1:1080"
      ];
    };
  })
])

