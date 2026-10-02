{ config, pkgs, ... }:
{
  services.fprintd = {
    enable = true;
    tod.enable = true;
    tod.driver = pkgs.libfprint-2-tod1-goodix;
  };
  security.pam.services.sudo.fprintAuth = true;

  # Don't use fingerprint when laptop lid closed.
  # https://discourse.nixos.org/t/temporarily-disable-fprintd/38296/2
  security.pam.services.sudo.rules.auth.fprintd-only-if-lid-open = {
    enable = true;
    order = config.security.pam.services.sudo.rules.auth.fprintd.order - 1;
    control = "[success=ok default=1]";
    modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
    args = [
      "quiet"
      "quiet_log"
      "${pkgs.writeShellScript "is-lid-open" ''
        set -euo pipefail
        lidstate="$(${config.systemd.package}/bin/busctl get-property org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager LidClosed 2>/dev/null)"
        if [ "''${lidstate}" = "b false" ]; then
          exit 0
        fi
        exit 1
      ''}"
    ];
  };
}
