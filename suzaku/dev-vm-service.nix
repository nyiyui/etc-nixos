{ self, pkgs, ... }:
let
  runner = self.nixosConfigurations.dev-vm.config.microvm.declaredRunner;

  startScript = pkgs.writeShellApplication {
    name = "dev-vm-service-start";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      e2fsprogs
      gnused
      iproute2
      openssh
      systemd
    ];
    text = ''
      ESCAPED="$1"
      WORKSPACE=$(systemd-escape --unescape --path -- "$ESCAPED")
      WORKSPACE=$(realpath "$WORKSPACE")
      VM_HOSTNAME=$(basename "$WORKSPACE")

      _HASH=$(printf '%s' "$WORKSPACE" | sha256sum | cut -c1-12)
      TAP="vm-$_HASH"
      MAC="02:''${_HASH:0:2}:''${_HASH:2:2}:''${_HASH:4:2}:''${_HASH:6:2}:''${_HASH:8:2}"

      VM_DIR="/var/lib/dev-vm/$_HASH"
      mkdir -p "$VM_DIR"

      if [ ! -f "$VM_DIR/id_ed25519" ]; then
        ssh-keygen -t ed25519 -f "$VM_DIR/id_ed25519" -N "" -C "dev-vm-$_HASH" >/dev/null
      fi

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

      echo "$VM_HOSTNAME" > "$VM_DIR/hostname"
      echo "$WORKSPACE" > "$VM_DIR/workspace-path"
      rm -f "$VM_DIR/ip"

      RUNDIR=$(mktemp -d)
      cd "$RUNDIR"

      BGPIDS=()
      /run/wrappers/bin/virtiofsd \
        --socket-path=dev-vm-virtiofs-ro-store.sock \
        --shared-dir=/nix/store \
        --thread-pool-size "$(nproc)" \
        --sandbox=chroot --xattr --cache=auto &
      BGPIDS+=($!)

      /run/wrappers/bin/virtiofsd \
        --socket-path=dev-vm-virtiofs-workspace.sock \
        --shared-dir="$WORKSPACE" \
        --thread-pool-size "$(nproc)" \
        --sandbox=chroot --xattr --cache=auto &
      BGPIDS+=($!)

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

      bash <(sed \
        -e "s/tap=vm-dev/tap=$TAP/g" \
        -e "s/mac=02:00:00:00:00:01/mac=$MAC/g" \
        -e "s|/run/user/1000/dev-vm-nix-store.img|$NIX_STORE_IMG|g" \
        -e "s|/run/user/1000/dev-vm-state.img|$STATE_IMG|g" \
        -e "s/--serial tty/--serial null/g" \
        ${runner}/bin/microvm-run)
    '';
  };
in
{
  systemd.services."dev-vm@" = {
    description = "Dev VM for %i";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      User = "kiyurica";
      Group = "kiyurica";
      ExecStart = "${startScript}/bin/dev-vm-service-start %i";
      KillMode = "mixed";
      TimeoutStopSec = "10s";
    };
  };
}
