{ pkgs, ... }:

let
  # No nixpkgs package exists; Jw_cad's installer couldn't be extracted w/
  # innoextract, so manually install it:
  #   WINEPREFIX=/home/kiyurica/.wine-jwcad wine jww10036.exe
  # Also run this for Japanese fonts:
  #   WINEPREFIX=/home/kiyurica/.wine-jwcad winetricks cjkfonts
  jwcadWinePrefix = "/home/kiyurica/.wine-jwcad";
  jwcad = pkgs.writeShellScriptBin "jw_cad" ''
    export WINEPREFIX="${jwcadWinePrefix}"
    exec ${pkgs.wine}/bin/wine "${jwcadWinePrefix}/drive_c/jww/Jw_win.exe" "$@"
  '';
  jwcadDesktopItem = pkgs.makeDesktopItem {
    name = "jw_cad";
    desktopName = "Jw_cad";
    exec = "${jwcad}/bin/jw_cad";
    categories = [
      "Graphics"
      "Engineering"
    ];
  };
in
{
  environment.systemPackages = [
    pkgs.wine
    pkgs.winetricks
    jwcad
    jwcadDesktopItem
  ];
}
