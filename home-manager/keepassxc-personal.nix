{
  config,
  lib,
  pkgs,
  ...
}:
let
  hasGeofront =
    (config ? osConfig) &&
    (config.osConfig.services.syncthing.settings.folders ? geofront);
in
{
  config = lib.mkIf hasGeofront {
    home.packages = [
      pkgs.keepassxc
      (pkgs.writeShellScriptBin "keepassxc-personal" ''
        exec keepassxc "$(${pkgs.findutils}/bin/find "${config.osConfig.services.syncthing.settings.folders.geofront.path}" -maxdepth 1 -name "personal-*.kdbx" | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/tail -n 1)"
      '')
    ];

    xdg.desktopEntries.keepassxc-personal = {
      name = "KeePassXC Personal";
      exec = "keepassxc-personal";
      icon = "keepassxc";
    };
  };
}
