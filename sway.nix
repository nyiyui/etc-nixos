{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./home-manager.nix ];

  options.kiyurica.desktop.sway.enable = lib.mkEnableOption "Sway-based";

  config = lib.mkIf config.kiyurica.desktop.sway.enable {
    home-manager.users.kiyurica = {
      imports = [
        ./home-manager/graphical.nix
        ./home-manager/sway.nix
      ];
    };

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
    services.displayManager.defaultSession = "sway-uwsm";
    programs.uwsm = {
      enable = true;
      waylandCompositors.sway = {
        binPath = "/run/current-system/sw/bin/sway";
        prettyName = "Sway";
        comment = "Sway-based session managed by UWSM";
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
      wlr = {
        enable = true;
        settings.screencast.max_fps = 30;
      };
      config.common.default = "wlr";
    };
    environment.systemPackages = with pkgs; [ pkgs.libsForQt5.qt5.qtwayland ];
    services.systemd-lock-handler.enable = true;
  };
}
