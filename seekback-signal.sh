#!/usr/bin/env bash
# This assumes a systemd user service running seekback.

SERVICE="seekback.service"
pid="$(systemctl --user show --property MainPID --value "$SERVICE")"
kill -USR1 "$pid"
