VM_BASE="${DEV_VM_BASE:-/var/lib/dev-vm}"

if [ ! -d "$VM_BASE" ]; then
  echo "No VMs found." >&2
  exit 0
fi

shopt -s nullglob
ALL_DIRS=("$VM_BASE"/*)
shopt -u nullglob

VM_DIRS=()
WORKSPACES=()
for vm_dir in "${ALL_DIRS[@]}"; do
  [ -d "$vm_dir" ] || continue
  workspace="(unknown)"
  if [ -f "$vm_dir/workspace-path" ]; then
    workspace=$(cat "$vm_dir/workspace-path")
  fi
  VM_DIRS+=("$vm_dir")
  WORKSPACES+=("$workspace")
done

if [ ${#VM_DIRS[@]} -eq 0 ]; then
  echo "No VMs found." >&2
  exit 0
fi

# Get a list of running VMs from the unit (instance) names.
declare -A RUNNING=()
while read -r unit _load active _rest; do
  case "$active" in active|activating) ;; *) continue ;; esac
  inst=${unit#dev-vm@}
  inst=${inst%.service}
  ws=$(systemd-escape --unescape --path "$inst" 2>/dev/null) || continue
  RUNNING["$ws"]=1
done < <(systemctl list-units 'dev-vm@*.service' --no-legend --plain 2>/dev/null)

for i in "${!VM_DIRS[@]}"; do
  vm_dir="${VM_DIRS[$i]}"
  workspace="${WORKSPACES[$i]}"

  if [ -n "${RUNNING[$workspace]:-}" ]; then
    status="RUNNING"
  else
    status="stopped"
  fi

  # Disk usage: actual (sparse-aware). One stat call covers all images;
  # %b is 512-byte blocks allocated, %B is the block size stat reports.
  actual=0
  shopt -s nullglob
  imgs=("$vm_dir"/*.img)
  shopt -u nullglob
  if [ ${#imgs[@]} -gt 0 ]; then
    while read -r blocks blksize; do
      actual=$((actual + blocks * blksize))
    done < <(stat --format='%b %B' "${imgs[@]}")
  fi

  # Last used: most recent mtime of any file in the VM dir.
  last_used=$(stat --format='%Y' "$vm_dir"/* 2>/dev/null | sort -rn | head -1)
  if [ -n "$last_used" ]; then
    printf -v last_used '%(%Y-%m-%d %H:%M:%S)T' "$last_used"
  else
    last_used="never"
  fi

  # $vm_dir has fixed length
  printf '%-9s  %12s  %-20s  %s  %s\n' \
    "$status" \
    "$(numfmt --to=iec-i --suffix=B "$actual")" \
    "$last_used" \
    "$vm_dir" \
    "$workspace"
done
