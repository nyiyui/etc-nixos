{ pkgs, ... }: {
  home.packages = [
    (pkgs.writeShellScriptBin "virtual-ti83" ''
      cd ${.}
      ${pkgs.wineWowPackages.full}/bin/wine ./vti83.exe
    '')
  ];
}
