{ pkgs, ... }: {
  imports = [
    ./8085
    ./virtual-ti83
  ];

  home.packages = [ pkgs.logisim ];
}
