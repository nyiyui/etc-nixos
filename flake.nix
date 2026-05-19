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

      packages.x86_64-linux.dev-vm =
        let
          cfg = nixosConfigurations.dev-vm.config;
          runner = cfg.microvm.declaredRunner;
          virtiofsd = cfg.microvm.virtiofsd.package;
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in
        pkgs.writeShellApplication {
          name = "dev-vm";
          text = ''
            WORKSPACE=''${1:-$PWD}
            VM_HOSTNAME=''${2:-$(basename "$WORKSPACE")}
            RUNDIR=$(mktemp -d)
            cd "$RUNDIR"

            # Write hostname for the guest to pick up at boot.
            echo "$VM_HOSTNAME" > "$WORKSPACE/.dev-vm-hostname"

            # Derive workspace hash early — used for TAP name, MAC, and disk paths.
            _HASH=$(printf '%s' "$WORKSPACE" | sha256sum | cut -c1-12)

            # Persistent disk images live in /var/lib/dev-vm/<hash>/ on the host,
            # which is covered by suzaku's impermanence /var/lib persistence.
            # Symlinked at runtime to the fixed paths the microvm config expects.
            RTDIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
            VM_DIR="/var/lib/dev-vm/$_HASH"
            mkdir -p "$VM_DIR"

            NIX_STORE_IMG="$VM_DIR/nix-store.img"
            NIX_STORE_LINK="$RTDIR/dev-vm-nix-store.img"
            if [ ! -f "$NIX_STORE_IMG" ]; then
              truncate -s 64G "$NIX_STORE_IMG"
              mkfs.ext4 -L nix-store "$NIX_STORE_IMG"
            fi
            ln -sf "$NIX_STORE_IMG" "$NIX_STORE_LINK"

            STATE_IMG="$VM_DIR/state.img"
            STATE_LINK="$RTDIR/dev-vm-state.img"
            if [ ! -f "$STATE_IMG" ]; then
              truncate -s 64G "$STATE_IMG"
              mkfs.ext4 -L dev-vm-state "$STATE_IMG"
            fi
            ln -sf "$STATE_IMG" "$STATE_LINK"

            # virtiofsd is setuid root — start it without doas.
            # ro-store share: host /nix/store (fixed)
            /run/wrappers/bin/virtiofsd \
              --socket-path=dev-vm-virtiofs-ro-store.sock \
              --shared-dir=/nix/store \
              --thread-pool-size "$(nproc)" \
              --sandbox=chroot --xattr --cache=auto &

            # workspace share: supplied path (default: $PWD at invocation)
            /run/wrappers/bin/virtiofsd \
              --socket-path=dev-vm-virtiofs-workspace.sock \
              --shared-dir="$WORKSPACE" \
              --thread-pool-size "$(nproc)" \
              --sandbox=chroot --xattr --cache=auto &

            for _ in $(seq 50); do
              [ -S dev-vm-virtiofs-ro-store.sock ] && \
              [ -S dev-vm-virtiofs-workspace.sock ] && break
              sleep 0.2
            done

            # TAP: "vm-" + first 12 hex chars of sha256(path) = 15 chars (IFNAMSIZ-1).
            # MAC: locally-administered unicast (02:xx:xx:xx:xx:xx) from same hash.
            TAP="vm-$_HASH"
            MAC="02:''${_HASH:0:2}:''${_HASH:2:2}:''${_HASH:4:2}:''${_HASH:6:2}:''${_HASH:8:2}"

            # Single doas call: TAP setup (when vm0 bridge exists) + socket chown.
            # Sockets are root-owned (setuid virtiofsd); cloud-hypervisor runs as
            # the user and needs to connect to them.
            doas sh -c "
              if ip link show vm0 >/dev/null 2>&1; then
                ip tuntap add dev '$TAP' mode tap multi_queue user '$(id -un)'
                ip link set '$TAP' master vm0
                ip link set '$TAP' up
              fi
              chown $(id -u) '$RUNDIR/dev-vm-virtiofs-ro-store.sock' '$RUNDIR/dev-vm-virtiofs-workspace.sock'
            "
            trap 'doas ip link delete "$TAP" 2>/dev/null || true; rm -f "$WORKSPACE/.dev-vm-hostname" "$NIX_STORE_LINK" "$STATE_LINK"; kill $(jobs -p) 2>/dev/null; rm -rf "$RUNDIR"' EXIT

            # Patch the baked-in TAP name and MAC in microvm-run at launch time.
            exec bash <(sed \
              -e "s/tap=vm-dev/tap=$TAP/g" \
              -e "s/mac=02:00:00:00:00:01/mac=$MAC/g" \
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
