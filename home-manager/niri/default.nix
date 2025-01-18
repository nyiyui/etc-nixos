{ ... }: {
  programs.niri.config = builtins.readFile ./config.kdl;
}
