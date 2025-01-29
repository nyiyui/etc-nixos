{ specialArgs, config, pkgs, lib, ... }: {
  imports = [ specialArgs.niri.nixosModules.niri ];

  options.nyiyui.desktop.niri.enable = lib.mkEnableOption "Niri";

  config = lib.mkIf config.nyiyui.desktop.niri.enable {
    programs.niri.enable = true;
    nixpkgs.overlays = [ specialArgs.niri.overlays.niri ];
    home-manager.users.nyiyui = {
      imports = [ ./home-manager/graphical.nix ./home-manager/niri ./home-manager/fuzzel.nix ];
    };
    services.displayManager.defaultSession = "niri";
    niri-flake.cache.enable = false;
  
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        pkgs.xdg-desktop-portal-gnome
      ];
      config.common.default = "gnome";
    };
  };
}
