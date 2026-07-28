VM_BASE="/var/lib/dev-vm"

if [ ! -d "$VM_BASE" ]; then
  echo "No VMs found." >&2
  exit 0
fi

# Collect VM dirs (each is a hash directory)
shopt -s nullglob
VM_DIRS=("$VM_BASE"/*)
shopt -u nullglob

if [ ${#VM_DIRS[@]} -eq 0 ]; then
  echo "No VMs found." >&2
  exit 0
fi

human_size() {
  numfmt --to=iec-i --suffix=B "$1"
}

for vm_dir in "${VM_DIRS[@]}"; do
  [ -d "$vm_dir" ] || continue

  # Read workspace path
  workspace="(unknown)"
  if [ -f "$vm_dir/workspace-path" ]; then
    workspace=$(cat "$vm_dir/workspace-path")
  fi

  # Determine systemd service status
  escaped=$(systemd-escape --path "$workspace" 2>/dev/null || echo "unknown")
  service="dev-vm@${escaped}.service"
  status=$(systemctl is-active "$service" 2>/dev/null || echo "stopped")
  case "$status" in
    active|activating) status="running" ;;
    *) status="stopped" ;;
  esac

  # Disk usage: actual (sparse-aware)
  actual=0
  for img in "$vm_dir"/*.img; do
    [ -f "$img" ] || continue
    blocks=$(stat --format='%b' "$img")
    blksize=$(stat --format='%B' "$img")
    actual=$((actual + blocks * blksize))
  done

  # Last used: most recent mtime of any file in the VM dir
  last_used=$(stat --format='%Y' "$vm_dir"/* 2>/dev/null | sort -rn | head -1)
  if [ -n "$last_used" ]; then
    last_used=$(date -d "@$last_used" '+%Y-%m-%d %H:%M:%S')
  else
    last_used="never"
  fi

  printf '%-9s  %12s  %-20s  %-60s  %s\n' \
    "$status" \
    "$(human_size $actual)" \
    "$last_used" \
    "$vm_dir" \
    "$workspace"
done
