{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
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
    # lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    polar-data-collector.url = "github:VR-state-analysis/polar-data-collector";
    polar-data-collector.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
    sync-pdf-viewer.url = "github:nyiyui/sync-pdf-viewer";
    sync-pdf-viewer.inputs.nixpkgs.follows = "nixpkgs";
    niri.url = "github:sodiboo/niri-flake";
    niri.inputs.nixpkgs.follows = "nixpkgs";
    declarative-flatpak.url = "github:in-a-dil-emma/declarative-flatpak/latest";
    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixwrap.url = "github:rti/nixwrap";
    nixwrap.inputs.nixpkgs.follows = "nixpkgs";
    nixwrap.inputs.flake-utils.follows = "flake-utils";
    assr.url = "github:nyiyui/assr";
    assr.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      agenix,
      nixpkgs,
      flake-utils,
      lanzaboote,
      ...
    }@attrs:
    rec {
      nixosConfigurations.thecutie = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // {
          inherit system;
        };
        modules = [
          ./thecutie/configuration.nix
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
          ];
        };
      }
    );
}
