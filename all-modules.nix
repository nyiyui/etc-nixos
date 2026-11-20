{ assr, ... }:
{
  # all modules which have an explicit "enable" option to prevent unintended enables for ease of debugging etc
  imports = [
    assr.nixosModules.wlsunset
    ./gtkgreet.nix
    ./tailscale-cert.nix
    ./tailscale-creds.nix
    ./autoUpgrade-git.nix
    ./laptop.nix
    assr.nixosModules.displaylink
    # by path, not assr.nixosModules.eduroam, so ./eduroam.nix can disabledModules it
    "${assr}/eduroam"
    ./mosh.nix
    ./quaderno-sync.nix
    ./caldav-canvas-gradescope.nix
    ./backup-caldav
    ./backup-persist-push
    ./power-logger
    ./nmea-static-gps-server
    assr.nixosModules.ocproxy
  ];
}
