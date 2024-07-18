{ pkgs, lib, ... }:
{
  services.wlsunset = {
    enable = true;
    sunrise = "07:00";
    sunset = "17:00";
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
