{
  # WIP
  programs.evolution.enable = true;
  programs.evolution.plugins = [ pkgs.evolution-ews ];
  services.evolution-data-server.enable = true;
  services.gnome-keyring.enable = true;
}
