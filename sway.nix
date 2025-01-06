{ pkgs, ... }: {
  imports = [ ./home-manager.nix ];

  programs.sway.enable = true;
  home-manager.users.nyiyui = {
    imports = [ ./home-manager/graphical.nix ./home-manager/sway.nix ];
  };
  services.displayManager.defaultSession = "sway";

  xdg.portal = {
    enable = true;
    configPackages = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
    wlr.enable = true;
    config.common.default = "wlr";
  };
  environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
}
