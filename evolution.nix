{ pkgs, ... }: {
  # WIP
  programs.evolution.enable = true;
  programs.evolution.plugins = [ pkgs.evolution-ews ];
  services.gnome.evolution-data-server.enable = true;
  services.gnome.gnome-keyring.enable = true;
}
