{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    jks.url = "github:nyiyui/jks";
    jks.inputs.nixpkgs.follows = "nixpkgs";
    jks.inputs.flake-utils.follows = "flake-utils";
    jts.url = "github:nyiyui/jts";
    jts.inputs.nixpkgs.follows = "nixpkgs";
    jts.inputs.flake-utils.follows = "flake-utils";
    seekback-server.url = "github:nyiyui/seekback-server";
    seekback-server.inputs.nixpkgs.follows = "nixpkgs";
    seekback-server.inputs.flake-utils.follows = "flake-utils";
    touhoukou.url = "github:nyiyui/touhoukou";
    touhoukou.inputs.nixpkgs.follows = "nixpkgs";
    touhoukou.inputs.flake-utils.follows = "flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    seekback.url = "github:nyiyui/seekback";
    seekback.inputs.nixpkgs.follows = "nixpkgs";
    seekback.inputs.flake-utils.follows = "flake-utils";
    niri.url = "github:sodiboo/niri-flake";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.2";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    polar-data-collector.url = "github:VR-state-analysis/polar-data-collector";
    polar-data-collector.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, agenix, nixpkgs, flake-utils, niri, lanzaboote, ... }@attrs:
    let pkgs = import nixpkgs { config.allowUnfree = true; };
    in rec {
      nixosConfigurations.mitsu8 = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // { inherit system; };
        modules = [ ./mitsu8/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.minato = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // { inherit system; };
        modules = [ ./minato/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.yagoto = nixpkgs.lib.nixosSystem rec {
        system = "aarch64-linux";
        specialArgs = attrs // { inherit system; };
        modules = [ ./yagoto/configuration.nix agenix.nixosModules.default ];
      };
      images.yagoto = nixosConfigurations.yagoto.config.system.build.sdImage;
      nixosConfigurations.sekisho2 = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // { inherit system; };
        modules = [ ./sekisho2/configuration.nix ];
      };
      nixosConfigurations.suzaku = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // { inherit system; };
        modules = [ ./suzaku/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.inaho = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = attrs // { inherit system; };
        modules = [ ./inaho/configuration.nix agenix.nixosModules.default ];
      };
    } // flake-utils.lib.eachSystem flake-utils.lib.defaultSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt-rfc-style
            (python3.withPackages (p: [ p.pyserial ]))
          ];
        };
      });
}
