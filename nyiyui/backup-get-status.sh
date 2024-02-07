systemctl show backup-restic --property=ActiveExitTimestamp | cut -d'=' -f2-
systemctl show backup-restic --property=Result | cut -d'=' -f2-
