{ pkgs, lib, ... }:
{
  services.wlsunset = {
    enable = true;
    #latitude = lib.mkDefault "43.65";
    #longitude = lib.mkDefault "-79.38"; # Toronto
    latitude = lib.mkDefault "35.67";
    longitude = lib.mkDefault "139.65"; # Tokyo
    temperature = {
      day = lib.mkDefault 6500;
      night = lib.mkDefault 2000;
    };
  };
  home.packages = [
    (pkgs.writeShellScriptBin "sunrise" ''
      systemctl --user stop wlsunset
    '')
    (pkgs.writeShellScriptBin "sunset" ''
      systemctl --user restart wlsunset
    '')
  ];
}
