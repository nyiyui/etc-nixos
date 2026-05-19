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

            # Set up TAP networking if the vm0 bridge is present on this host.
            TAP=vm-dev
            if ip link show vm0 &>/dev/null; then
              sudo ip tuntap add dev "$TAP" mode tap user "$(id -un)"
              sudo ip link set "$TAP" master vm0
              sudo ip link set "$TAP" up
              trap 'sudo ip link delete "$TAP" 2>/dev/null || true; rm -f "$WORKSPACE/.dev-vm-hostname"; kill $(jobs -p) 2>/dev/null; rm -rf "$RUNDIR"' EXIT
            else
              trap 'rm -f "$WORKSPACE/.dev-vm-hostname"; kill $(jobs -p) 2>/dev/null; rm -rf "$RUNDIR"' EXIT
            fi

            # ro-store share: host /nix/store (fixed)
            ${virtiofsd}/bin/virtiofsd \
              --socket-path=dev-vm-virtiofs-ro-store.sock \
              --shared-dir=/nix/store \
              --thread-pool-size "$(nproc)" \
              --posix-acl --xattr --cache=auto --inode-file-handles=prefer &

            # workspace share: supplied path (default: $PWD at invocation)
            ${virtiofsd}/bin/virtiofsd \
              --socket-path=dev-vm-virtiofs-workspace.sock \
              --shared-dir="$WORKSPACE" \
              --thread-pool-size "$(nproc)" \
              --posix-acl --xattr --cache=auto --inode-file-handles=prefer &

            for _ in $(seq 50); do
              [ -S dev-vm-virtiofs-ro-store.sock ] && \
              [ -S dev-vm-virtiofs-workspace.sock ] && break
              sleep 0.2
            done

            exec ${runner}/bin/microvm-run
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
