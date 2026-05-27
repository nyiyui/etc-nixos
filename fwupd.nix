{ pkgs, ... }:

let
  fwupd-notify = pkgs.writeShellScript "fwupd-notify" ''
    set -euo pipefail

    export LANG=C.UTF-8
    export LC_ALL=C

    # Check for updates (no refresh as user, requires root)
    updates=$(/run/current-system/sw/bin/fwupdmgr get-updates 2>/dev/null || true)

    if echo "$updates" | grep -q "No upgrades"; then
      exit 0
    fi

    # If we found updates, send notification
    if echo "$updates" | grep -q "│"; then
      ${pkgs.notify-desktop}/bin/notify-desktop \
        -u normal \
        -i system-software-update \
        -a fwupd-notify.service \
        "Firmware Updates Available" \
        "Run 'fwupdmgr update' to install firmware updates. Note that automatic disk encryption may be reset on next boot."
    fi
  '';
in
{
  services.fwupd.enable = true;

  # User service for notifications
  systemd.user.services.fwupd-notify = {
    description = "Check for firmware updates and notify";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${fwupd-notify}";
    };
  };

  systemd.user.timers.fwupd-notify = {
    description = "Check for firmware updates daily";
    timerConfig = {
      OnBootSec = "15m";
      OnUnitActiveSec = "1d";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}
