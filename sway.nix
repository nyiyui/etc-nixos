{ config, pkgs, lib, ... }: {
  imports = [ ./home-manager.nix ];

  options.nyiyui.desktop.sway.enable = lib.mkEnableOption "Sway-based";

  config = lib.mkIf config.nyiyui.desktop.sway.enable {
    home-manager.users.nyiyui = {
      imports = [ ./home-manager/graphical.nix ./home-manager/sway.nix ];
    };
  
    programs.sway.enable = true;
    services.displayManager.defaultSession = "sway";
  
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
      wlr = {
        enable = true;
        settings.screencast.max_fps = 30;
      };
      config.common.default = "wlr";
    };
    environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
  };
}
