{
  config,
  lib,
  pkgs,
  ...
}:

let
  update-notify = pkgs.writeShellScript "update-notify" ''
    set -euo pipefail

    export LANG=C.UTF-8
    export LC_ALL=C

    updatectl check > /dev/null 2>&1

    # Check for newer versions
    # updatectl list output contains a "NEWER" column which indicates if a newer version is available.
    updates=$(updatectl list 2>/dev/null)

    if echo "$updates" | grep -q "yes"; then
      ${pkgs.libnotify}/bin/notify-send \
        -u normal \
        -i system-software-update \
        -a update-notify.service \
        "System Updates Available" \
        "Newer system versions are available. Use 'updatectl update' to install."
    fi
  '';
in
{
  # User service for notifications
  home-manager.sharedModules = [
    {
      systemd.user.services.update-notify = {
        Unit = {
          Description = "Check for system updates and notify";
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${update-notify}";
        };
      };

      systemd.user.timers.update-notify = {
        Unit = {
          Description = "Check for system updates daily";
        };
        Timer = {
          OnBootSec = "15m";
          OnUnitActiveSec = "1d";
          Persistent = true;
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    }
  ];
}
