#!/usr/bin/env bash

if [ -z "$DB_PATH" ]; then
  1>&2 echo 'DB_PATH must be set'
  exit 1
fi

SCHEMA="CREATE TABLE IF NOT EXISTS focused_windows (name TEXT, app_id TEXT, created_at INTEGER);"

echo "$SCHEMA" | sqlite3 $DB_PATH

echo "monitoring…"
swaymsg -t subscribe -m '["window"]' \
  | jq -r --unbuffered 'select(.change=="focus" or .change=="title") | .container | [.name, .app_id, now] | @tsv' \
  | sqlite3 $DB_PATH -tabs '.import /dev/stdin focused_windows'
