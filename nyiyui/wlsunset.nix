{ pkgs, lib, ... }:
{
  services.wlsunset = {
    enable = true;
    latitude = lib.mkDefault "35.67";
    longitude = lib.mkDefault "129.65";
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
