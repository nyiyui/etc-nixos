{ pkgs, ... }: {
  imports = [ ./wlsunset.nix ];

  home.packages = with pkgs; [ wl-clipboard ];
}
