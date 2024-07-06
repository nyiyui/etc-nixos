{ specialArgs, pkgs, ... }: {
  imports = [ specialArgs.niri.nixosModules.niri ];

  programs.niri.enable = true;
  nixpkgs.overlays = [ specialArgs.niri.overlays.niri ];
  home-manager.users.nyiyui = {
    imports = [ ./nyiyui/graphical.nix ./nyiyui/niri ./nyiyui/fuzzel.nix ];
  };
  services.displayManager.defaultSession = "niri";
  niri-flake.cache.enable = false;

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      pkgs.xdg-desktop-portal-gnome
      (pkgs.xdg-desktop-portal-gtk.override {
        # Do not build portals that we already have.
        buildPortalsInGnome = false;
      })
    ];
    config.common.default = "wlr";
  };
}
