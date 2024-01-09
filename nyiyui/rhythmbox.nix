{ pkgs, ... }: {
  home.packages = with pkgs; [ rhythmbox ];
  # TODO: GSettings?
}
