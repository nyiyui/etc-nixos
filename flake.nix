{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11"; # temporary for CVE-2026-39860
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";
    # lanzaboote.inputs.nixpkgs.follows = "nixpkgs"; # lanzaboote previously didn't work with follow
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
    sync-pdf-viewer.url = "github:nyiyui/sync-pdf-viewer";
    sync-pdf-viewer.inputs.nixpkgs.follows = "nixpkgs";
    sync-pdf-viewer.inputs.flake-utils.follows = "flake-utils";
    niri.url = "github:sodiboo/niri-flake";
    niri.inputs.nixpkgs.follows = "nixpkgs";
    niri.inputs.nixpkgs-stable.follows = "nixpkgs";
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    caldav-canvas-gradescope.url = "github:nyiyui/caldav-canvas-gradescope";
    caldav-canvas-gradescope.inputs.nixpkgs.follows = "nixpkgs";
    caldav-canvas-gradescope.inputs.flake-utils.follows = "flake-utils";
    microvm.url = "github:microvm-nix/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
    hjem.follows = "hjem-rum/hjem";
    hjem-rum = {
      url = "github:snugnug/hjem-rum";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      agenix,
      nixpkgs,
      flake-utils,
      lanzaboote,
      microvm,
      hjem,
      hjem-rum,
      ...
    }@attrs:
    rec {
      nixosConfigurations.mitsu8 = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // {
          inherit system;
        };
        modules = [
          ./mitsu8/configuration.nix
          agenix.nixosModules.default
          {
            nixpkgs.overlays = [
              (final: prev: {
                python310 = attrs.nixpkgs-unstable.legacyPackages.${system}.python310;
              })
            ];
          }
        ];
      };
      nixosConfigurations.minato = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // {
          inherit system;
        };
        modules = [
          ./minato/configuration.nix
          agenix.nixosModules.default
          {
            nixpkgs.overlays = [
              (final: prev: {
                python310 = attrs.nixpkgs-unstable.legacyPackages.${system}.python310;
              })
            ];
          }
        ];
      };
      nixosConfigurations.suzaku = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // {
          inherit system;
        };
        modules = [
          ./suzaku/configuration.nix
          agenix.nixosModules.default
          hjem.nixosModules.default
          microvm.nixosModules.host
        ];
      };
      nixosConfigurations.inaho = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // {
          inherit system;
        };
        modules = [
          ./inaho/configuration.nix
          agenix.nixosModules.default
        ];
      };
      nixosConfigurations.misaki = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // {
          inherit system;
        };
        modules = [
          ./misaki/configuration.nix
          agenix.nixosModules.default
        ];
      };
      nixosConfigurations.minamo = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // {
          inherit system;
        };
        modules = [
          ./minamo/configuration.nix
          agenix.nixosModules.default
        ];
      };
      nixosConfigurations.currant = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = attrs // {
          inherit system;
        };
        modules = [
          ./currant/configuration.nix
          agenix.nixosModules.default
        ];
      };
      nixosConfigurations.dev-vm = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // {
          inherit system;
        };
        modules = [
          microvm.nixosModules.microvm
          ./dev-vm/configuration.nix
        ];
      };

      packages.x86_64-linux.dev-vm-start =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        pkgs.writeShellApplication {
          name = "dev-vm-start";
          runtimeInputs = with pkgs; [ coreutils systemd ];
          text = ''
            WORKSPACE=''${1:-$PWD}
            WORKSPACE=$(realpath "$WORKSPACE")
            ESCAPED=$(systemd-escape --path "$WORKSPACE")
            exec systemctl start "dev-vm@''${ESCAPED}.service"
          '';
        };

      packages.x86_64-linux.dev-vm-ssh =
        let
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        pkgs.writeShellApplication {
          name = "dev-vm-ssh";
          runtimeInputs = with pkgs; [ coreutils openssh ];
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

            IP=""
            echo "waiting for VM..." >&2
            for _ in $(seq 60); do
              IP=$(cat "$VM_DIR/ip" 2>/dev/null || true)
              if [ -n "$IP" ] && ssh \
                  -i "$VM_DIR/id_ed25519" \
                  -o StrictHostKeyChecking=no \
                  -o UserKnownHostsFile=/dev/null \
                  -o ConnectTimeout=2 \
                  -o BatchMode=yes \
                  "kiyurica@$IP" true 2>/dev/null; then
                break
              fi
              IP=""
              sleep 1
            done

            if [ -z "$IP" ]; then
              echo "dev-vm-ssh: timed out waiting for VM SSH." >&2
              exit 1
            fi

            echo "connecting to $IP..." >&2
            exec ssh \
              -i "$VM_DIR/id_ed25519" \
              -o StrictHostKeyChecking=no \
              -o UserKnownHostsFile=/dev/null \
              "kiyurica@$IP"
          '';
        };

      packages.x86_64-linux.dev-vm =
        let
          cfg = nixosConfigurations.dev-vm.config;
          runner = cfg.microvm.declaredRunner;
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        pkgs.writeShellApplication {
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
    // flake-utils.lib.eachSystem flake-utils.lib.defaultSystems (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt-rfc-style
            (python3.withPackages (p: [
              p.pyserial
              p.caldav
            ]))
            go
            nixd
          ];
        };
      }
    );
}
