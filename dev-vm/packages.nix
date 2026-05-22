{ pkgs, self }:

let
  cfg = self.nixosConfigurations.dev-vm.config;
  runner = cfg.microvm.declaredRunner;
in
{
  dev-vm-start = pkgs.writeShellApplication {
    name = "dev-vm-start";
    runtimeInputs = with pkgs; [
      coreutils
      systemd
    ];
    text = ''
      WORKSPACE=''${1:-$PWD}
      WORKSPACE=$(realpath "$WORKSPACE")
      ESCAPED=$(systemd-escape --path "$WORKSPACE")
      exec systemctl start "dev-vm@''${ESCAPED}.service"
    '';
  };

  dev-vm-ssh = pkgs.writeShellApplication {
    name = "dev-vm-ssh";
    runtimeInputs = with pkgs; [
      coreutils
      openssh
    ];
    text = ''
      WORKSPACE=''${1:-$PWD}
      WORKSPACE=$(realpath "$WORKSPACE")

      _HASH=$(printf '%s' "$WORKSPACE" | sha256sum | cut -c1-12)
      VM_DIR="/var/lib/dev-vm/$_HASH"

      if [ ! -d "$VM_DIR" ]; then
        echo "dev-vm-ssh: no VM directory for $WORKSPACE (expected $VM_DIR)" >&2
        exit 1
      fi

      if [ ! -f "$VM_DIR/id_ed25519" ]; then
        echo "dev-vm-ssh: no SSH key in $VM_DIR" >&2
        exit 1
      fi

      IP="$(cat "$VM_DIR"/ip)"
      echo "connecting to $IP..." >&2
      exec ssh \
        -i "$VM_DIR/id_ed25519" \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "kiyurica@$IP"
    '';
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
          --) seen_dashdash=true ;;
          *) WORKSPACE="$arg" ;;
        esac
      done

      WORKSPACE=''${WORKSPACE:-$PWD}
      WORKSPACE=$(realpath "$WORKSPACE")

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
          if ssh \
            -i "$VM_DIR/id_ed25519" \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o ConnectTimeout=2 \
            -o BatchMode=yes \
            "kiyurica@$IP" true 2>/dev/null; then
            return 0
          fi
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

  dev-vm = pkgs.writeShellApplication {
    name = "dev-vm";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      e2fsprogs
      gnused
      iproute2
      openssh
    ];
    text = ''
      WORKSPACE=''${1:-$PWD}
      WORKSPACE=$(realpath "$WORKSPACE")
      VM_HOSTNAME=''${2:-$(basename "$WORKSPACE")}

      # Derive workspace hash — used for TAP name, MAC, and disk paths.
      _HASH=$(printf '%s' "$WORKSPACE" | sha256sum | cut -c1-12)
      TAP="vm-$_HASH"
      MAC="02:''${_HASH:0:2}:''${_HASH:2:2}:''${_HASH:4:2}:''${_HASH:6:2}:''${_HASH:8:2}"

      VM_DIR="/var/lib/dev-vm/$_HASH"
      mkdir -p "$VM_DIR"

      # Per-workspace SSH keypair (generated once, reused across boots).
      if [ ! -f "$VM_DIR/id_ed25519" ]; then
        ssh-keygen -t ed25519 -f "$VM_DIR/id_ed25519" -N "" -C "dev-vm-$_HASH" >/dev/null
      fi

      # If the TAP exists the VM is already running — open a new SSH session.
      if ip link show "$TAP" >/dev/null 2>&1; then
        IP=""
        echo "waiting for VM..." >&2
        for _ in $(seq 60); do
          IP=$(cat "$VM_DIR/ip" 2>/dev/null || true)
          if [ -n "$IP" ]; then
            ssh \
              -i "$VM_DIR/id_ed25519" \
              -o StrictHostKeyChecking=no \
              -o UserKnownHostsFile=/dev/null \
              -o ConnectTimeout=2 \
              -o BatchMode=yes \
              "kiyurica@$IP" true 2>/dev/null && break
          fi
          sleep 1
        done
        if [ -z "$IP" ]; then
          echo "Timed out waiting for VM SSH." >&2
          exit 1
        fi
        echo "connecting to $IP..." >&2
        exec ssh \
          -i "$VM_DIR/id_ed25519" \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          "kiyurica@$IP"
      fi

      # --- VM not running: boot it. ---
      echo "starting VM..." >&2
      RUNDIR=$(mktemp -d)
      cd "$RUNDIR"

      NIX_STORE_IMG="$VM_DIR/nix-store.img"
      if [ ! -f "$NIX_STORE_IMG" ]; then
        truncate -s 128G "$NIX_STORE_IMG"
        mkfs.ext4 -L nix-store "$NIX_STORE_IMG"
      fi

      STATE_IMG="$VM_DIR/state.img"
      if [ ! -f "$STATE_IMG" ]; then
        truncate -s 128G "$STATE_IMG"
        mkfs.ext4 -L dev-vm-state "$STATE_IMG"
      fi

      # Write hostname and workspace path into vm-meta; clear stale IP from any previous run.
      echo "$VM_HOSTNAME" > "$VM_DIR/hostname"
      echo "$WORKSPACE" > "$VM_DIR/workspace-path"
      rm -f "$VM_DIR/ip"

      BGPIDS=()

      # virtiofsd is setuid root — start without doas.
      # ro-store share: host /nix/store (read-only).
      /run/wrappers/bin/virtiofsd \
        --socket-path=dev-vm-virtiofs-ro-store.sock \
        --shared-dir=/nix/store \
        --thread-pool-size "$(nproc)" \
        --sandbox=chroot --xattr --cache=auto &
      BGPIDS+=($!)

      # workspace share: the supplied project directory.
      /run/wrappers/bin/virtiofsd \
        --socket-path=dev-vm-virtiofs-workspace.sock \
        --shared-dir="$WORKSPACE" \
        --thread-pool-size "$(nproc)" \
        --sandbox=chroot --xattr --cache=auto &
      BGPIDS+=($!)

      # vm-meta share: $VM_DIR (hostname, SSH pubkey, IP written by guest).
      /run/wrappers/bin/virtiofsd \
        --socket-path=dev-vm-virtiofs-vm-meta.sock \
        --shared-dir="$VM_DIR" \
        --thread-pool-size "$(nproc)" \
        --sandbox=chroot --xattr --cache=auto &
      BGPIDS+=($!)

      for _ in $(seq 50); do
        [ -S dev-vm-virtiofs-ro-store.sock ] && \
        [ -S dev-vm-virtiofs-workspace.sock ] && \
        [ -S dev-vm-virtiofs-vm-meta.sock ] && break
        sleep 0.2
      done

      # Single doas call: TAP setup (when vm0 bridge exists) + socket chown.
      # Sockets are root-owned (setuid virtiofsd); cloud-hypervisor runs as
      # the user and needs to connect to them.
      doas sh -c "
        if ip link show vm0 >/dev/null 2>&1; then
          ip tuntap add dev '$TAP' mode tap multi_queue user '$(id -un)'
          ip link set '$TAP' master vm0
          ip link set '$TAP' up
        fi
        chown $(id -u) \
          '$RUNDIR/dev-vm-virtiofs-ro-store.sock' \
          '$RUNDIR/dev-vm-virtiofs-workspace.sock' \
          '$RUNDIR/dev-vm-virtiofs-vm-meta.sock'
      "

      cleanup() {
        doas ip link delete "$TAP" 2>/dev/null || true
        kill "''${BGPIDS[@]}" 2>/dev/null || true
        rm -rf "$RUNDIR"
      }
      trap cleanup EXIT

      # Run VM in foreground — console attached to current terminal.
      # Cleanup trap fires when microvm-run exits (VM shutdown).
      bash <(sed \
        -e "s/tap=vm-dev/tap=$TAP/g" \
        -e "s/mac=02:00:00:00:00:01/mac=$MAC/g" \
        -e "s|/run/user/1000/dev-vm-nix-store.img|$NIX_STORE_IMG|g" \
        -e "s|/run/user/1000/dev-vm-state.img|$STATE_IMG|g" \
        ${runner}/bin/microvm-run)
    '';
  };
}
