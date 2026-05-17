{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-25.11"; # temporary for CVE-2026-39860
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-25.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    touhoukou.url = "github:nyiyui/touhoukou";
    touhoukou.inputs.nixpkgs.follows = "nixpkgs";
    touhoukou.inputs.flake-utils.follows = "flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.3";
    # lanzaboote.inputs.nixpkgs.follows = "nixpkgs"; # lanzaboote previously didn't work with follow
    polar-data-collector.url = "github:VR-state-analysis/polar-data-collector";
    polar-data-collector.inputs.nixpkgs.follows = "nixpkgs";
    polar-data-collector.inputs.flake-utils.follows = "flake-utils";
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
    nixwrap.url = "github:rti/nixwrap";
    nixwrap.inputs.nixpkgs.follows = "nixpkgs";
    nixwrap.inputs.flake-utils.follows = "flake-utils";
    caldav-canvas-gradescope.url = "github:nyiyui/caldav-canvas-gradescope";
    caldav-canvas-gradescope.inputs.nixpkgs.follows = "nixpkgs";
    caldav-canvas-gradescope.inputs.flake-utils.follows = "flake-utils";
    hjem.follows = "hjem-rum/hjem"; # Hjem Rum recommends flake users to follow their Hjem input (an example is given below).
    hjem-rum = {
        url = "github:snugnug/hjem-rum";
        inputs.nixpkgs.follows = "nixpkgs";
        inputs.hjem.follows = "hjem";
    };
  };

  outputs =
    {
      self,
      agenix,
      nixpkgs,
      flake-utils,
      lanzaboote,
      hjem,
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
