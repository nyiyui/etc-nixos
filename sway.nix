{ pkgs, ... }: {
  imports = [ ./home-manager.nix ];
  home-manager.users.nyiyui = {
    imports = [ ./home-manager/graphical.nix ./home-manager/sway.nix ];
  };

  programs.sway.enable = true;
  services.displayManager.defaultSession = "sway";

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
    ];
    wlr.enable = true;
    config.common.default = "wlr";
  };
  environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
}
