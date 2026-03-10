{ pkgs, ... }:

{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-vaapi
      obs-vkcapture
      obs-gstreamer
      wlrobs
      obs-pipewire-audio-capture
    ];
  };
}
