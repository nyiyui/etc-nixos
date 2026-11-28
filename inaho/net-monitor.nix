{ pkgs, ... }:
{
  # Check connectivity once a minute and append a tab-separated line
  # (timestamp, check, reason) to /var/lib/net-monitor/failures-YYYY-MM-DD.log
  # for each check that fails.
  #
  # curl is deliberately run without -f: any HTTP response, including an
  # error status, counts as success. Only a timeout, DNS failure, refused
  # connection or TLS failure makes it exit non-zero.
  systemd.services.net-monitor = {
    description = "Check connectivity and record failures";
    path = with pkgs; [
      iputils
      curl
      coreutils
    ];
    serviceConfig = {
      Type = "oneshot";
      StateDirectory = "net-monitor";
      ExecStart = pkgs.writeShellScript "net-monitor" ''
        for check in \
          "ping -c 1 -W 5 8.8.8.8" \
          "ping -c 1 -W 5 1.1.1.1" \
          "curl -sS -o /dev/null --max-time 10 https://google.com"
        do
          out=$($check 2>&1) || {
            # one date call, so the stamp and the file it lands in can never
            # disagree across a midnight boundary
            now=$(date -Is)
            printf '%s\t%s\t%s\n' "$now" "$check" "$(echo "$out" | tail -n 1)" \
              >> /var/lib/net-monitor/failures-"''${now%%T*}".log
          }
        done
      '';
    };
  };

  systemd.timers.net-monitor = {
    description = "Check connectivity every minute";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "minutely";
      AccuracySec = "1s";
    };
  };

  # Keep a year of daily logs. "e" only ages the contents of an existing
  # directory - StateDirectory above owns creating it - and the files are
  # append-only, so each one's mtime is the last day it recorded a failure.
  systemd.tmpfiles.rules = [ "e /var/lib/net-monitor - - - 365d" ];
}
