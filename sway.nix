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
    kiyurica.home-manager.enable = true;
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
    programs.uwsm = {
      enable = true;
      waylandCompositors = { };
    };
    kiyurica.greeter.gtkgreet.compositor = [
      "/run/current-system/sw/bin/sway --unsupported-gpu"
    ];

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
