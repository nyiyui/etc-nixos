{ pkgs, ... }:

{
  dev-vm-list = pkgs.writeShellApplication {
    name = "dev-vm-list";
    runtimeInputs = with pkgs; [
      coreutils
      systemd
    ];
    text = builtins.readFile ./dev-vm-list.sh;
  };

  dev-vm-enter = pkgs.writeShellApplication {
    name = "dev-vm-enter";
    runtimeInputs = with pkgs; [
      coreutils
      openssh
      systemd
      waypipe
    ];
    text = ''
      WAYPIPE=false
      RECURSIVE_EXISTING=true
      WORKSPACE=""
      SSH_CMD=()

      # SSH options (e.g. -NL 8080:localhost:8080) can be passed via DEVVM_SSH_OPTS.
      # Positional args after -- are forwarded to SSH after the hostname (remote command).
      SSH_EXTRA_OPTS=()
      if [ -n "''${DEVVM_SSH_OPTS:-}" ]; then
        read -ra SSH_EXTRA_OPTS <<< "$DEVVM_SSH_OPTS"
      fi

      seen_dashdash=false
      for arg in "$@"; do
        if $seen_dashdash; then
          SSH_CMD+=("$arg")
          continue
        fi
        case "$arg" in
          --waypipe) WAYPIPE=true ;;
          --no-recursive-existing) RECURSIVE_EXISTING=false ;;
          --) seen_dashdash=true ;;
          *) WORKSPACE="$arg" ;;
        esac
      done

      WORKSPACE=''${WORKSPACE:-$PWD}
      WORKSPACE=$(realpath "$WORKSPACE")

      # Walk up from the workspace to the nearest ancestor that already has a VM
      # (running or not), so entering a subdirectory reuses the project's VM.
      if $RECURSIVE_EXISTING; then
        CANDIDATE="$WORKSPACE"
        while :; do
          if [ -d "/var/lib/dev-vm/$(printf '%s' "$CANDIDATE" | sha256sum | cut -c1-12)" ]; then
            if [ "$CANDIDATE" != "$WORKSPACE" ]; then
              echo "Using existing VM for $CANDIDATE (ancestor of $WORKSPACE)." >&2
            fi
            WORKSPACE="$CANDIDATE"
            break
          fi
          if [ "$CANDIDATE" = "/" ]; then
            break
          fi
          CANDIDATE=$(dirname "$CANDIDATE")
        done
      fi

      _HASH=$(printf '%s' "$WORKSPACE" | sha256sum | cut -c1-12)
      VM_DIR="/var/lib/dev-vm/$_HASH"
      ESCAPED=$(systemd-escape --path "$WORKSPACE")
      SERVICE="dev-vm@''${ESCAPED}.service"

      ssh_connect() {
        local IP="$1"
        if $WAYPIPE; then
          exec waypipe ssh \
            -i "$VM_DIR/id_ed25519" \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            "''${SSH_EXTRA_OPTS[@]}" \
            "kiyurica@$IP" \
            "''${SSH_CMD[@]}"
        else
          exec ssh \
            -i "$VM_DIR/id_ed25519" \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            "''${SSH_EXTRA_OPTS[@]}" \
            "kiyurica@$IP" \
            "''${SSH_CMD[@]}"
        fi
      }

      wait_for_ssh() {
        local IP="$1"
        for _ in $(seq 60); do
          local STATE
          STATE=$(timeout 5 ssh \
            -i "$VM_DIR/id_ed25519" \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=2 \
            -o BatchMode=yes \
            "kiyurica@$IP" systemctl is-system-running 2>/dev/null || true)
          case "$STATE" in
            running|degraded) return 0 ;;
          esac
          sleep 1
        done
        return 1
      }

      STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null || true)

      case "$STATUS" in
        active|activating)
          echo "VM is already running (''${STATUS})." >&2
          ;;
        *)
          echo "Starting VM for $WORKSPACE..." >&2
          systemctl start --no-block "$SERVICE"
          ;;
      esac

      # Wait for IP, printing systemd status every 10 s.
      echo "Waiting for VM to come up..." >&2
      IP=""
      for i in $(seq 120); do
        STATUS=$(systemctl is-active "$SERVICE" 2>/dev/null || true)
        if [ "$STATUS" = "failed" ]; then
          echo "VM service failed:" >&2
          systemctl status "$SERVICE" --no-pager -n 20 >&2 || true
          exit 1
        fi
        IP=$(cat "$VM_DIR/ip" 2>/dev/null || true)
        if [ -n "$IP" ]; then
          break
        fi
        if [ "$i" -eq 1 ] || [ $((i % 10)) -eq 0 ]; then
          systemctl status "$SERVICE" --no-pager -n 5 >&2 || true
        fi
        sleep 1
      done

      if [ -z "$IP" ]; then
        echo "Timed out waiting for VM IP." >&2
        exit 1
      fi

      echo "Waiting for SSH at $IP..." >&2
      if ! wait_for_ssh "$IP"; then
        echo "Timed out waiting for SSH." >&2
        exit 1
      fi

      echo "Connecting$(if $WAYPIPE; then echo " (waypipe)"; fi) to $IP..." >&2
      ssh_connect "$IP"
    '';
  };
}
