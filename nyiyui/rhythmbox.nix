{ pkgs, ... }: {
  home.packages = with pkgs; [ rhythmbox ];
  dconf.enable = true;
  dconf.settings = {
    #"org/gnome/rhythmbox/podcast".podcast.download-location = "";
    "org/gnome/rhythmbox/rhythmdb".locations = [
      "file:///home/nyiyui/inaba/music-library"
    ];
  };
  # TODO: GSettings?
}
