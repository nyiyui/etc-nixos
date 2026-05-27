{ pkgs, ... }:

let
  sysupdate-notify = pkgs.writeShellScript "sysupdate-notify" ''
    set -euo pipefail

    export LANG=C.UTF-8
    export LC_ALL=C

    updates=$(/run/current-system/sw/bin/updatectl check --no-pager --no-legend 2>/dev/null || true)

    # Output contains "→" only when an update is available (e.g. "host  48 → 50")
    if ! echo "$updates" | grep -qF "→"; then
      exit 0
    fi

    update_summary=$(echo "$updates" | grep -F "→" | awk '{print $1 " " $2 " " $3 " " $4}' | paste -sd', ')

    ${pkgs.notify-desktop}/bin/notify-desktop \
      -u normal \
      -i system-software-update \
      -a sysupdate-notify.service \
      "System Update Available" \
      "$update_summary. Run 'updatectl update' to install."
  '';
in
{
  systemd.user.services.sysupdate-notify = {
    description = "Check for system image updates and notify";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${sysupdate-notify}";
    };
  };

  systemd.user.timers.sysupdate-notify = {
    description = "Check for system image updates daily";
    timerConfig = {
      OnBootSec = "15m";
      OnUnitActiveSec = "1d";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}
