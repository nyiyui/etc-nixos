{ assr, ... }:
{
  # all modules which have an explicit "enable" option to prevent unintended enables for ease of debugging etc
  imports = [
    ./sway.nix
    ./niri
    ./wlsunset
    ./gtkgreet.nix
    ./tailscale.nix
    ./tailscale-cert.nix
    ./autoUpgrade-git.nix
    ./laptop.nix
    ./displaylink.nix
    assr.nixosModules.eduroam
    ./aiden.nix
    ./gatech-vpn.nix
    ./ocproxy.nix
    ./mosh.nix
    ./quaderno-sync.nix
    ./caldav-canvas-gradescope.nix
    ./backup-caldav
    ./backup-persist-push
    ./power-logger
    ./nmea-static-gps-server
  ];
}
