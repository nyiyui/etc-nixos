{ specialArgs, ... }: {
  imports = [ specialArgs.niri.nixosModules.niri ];

  programs.niri.enable = true;
  nixpkgs.overlays = [ specialArgs.niri.overlays.niri ];
  home-manager.users.nyiyui = {
    imports = [ ./nyiyui/graphical.nix ./nyiyui/niri ./nyiyui/fuzzel.nix ];
  };
  services.displayManager.defaultSession = "niri";
  niri-flake.cache.enable = false;
}
