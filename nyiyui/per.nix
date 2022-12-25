{ config, pkgs, lib, ... }:
(lib.mkMerge [
  (lib.mkIf (config.home.file.hostname.text == "kumi") {
  })
  (lib.mkIf (config.home.file.hostname.text == "miyo") {
    programs.foot.settings.main.font = "hack:size=12";
  })
])

