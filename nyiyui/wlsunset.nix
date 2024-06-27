{ pkgs, lib, ... }:
{
  services.wlsunset = {
    enable = true;
    latitude = lib.mkDefault "43.7159566";
    longitude = lib.mkDefault "-79.3702805";
    temperature = {
      day = lib.mkDefault 5000;
      night = lib.mkDefault 1500;
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
