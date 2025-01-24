{ ... }: {
  imports = [
    ../wayland.nix
  ];
  programs.niri.config = builtins.readFile ./config.kdl;
  programs.waybar.settings.mainBar = {
    modules-left = [
      "niri/workspaces"
    ];

    "niri/workspaces" = {
      current-only = true;
    };
  };
}
