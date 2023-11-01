#!/usr/bin/env bash
# This assumes a systemd user service running seekback.

SERVICE="seekback.service"

notif_id="$(notify-desktop -a seekback 'USR1…')"
pid="$(systemctl --user show --property MainPID --value "$SERVICE")"
kill -USR1 "$pid"
notif_id="$(notify-desktop -a seekback -r $notif_id -t 1000 'USR1.')"
