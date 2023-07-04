{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    qrystal.url = "github:nyiyui/qrystal/main";
    touhoukou.url = "github:nyiyui/touhoukou";
    touhoukou.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nix-serve-ng.url = github:aristanetworks/nix-serve-ng;
    flake-utils.url = github:numtide/flake-utils;
  };

  outputs = { self, agenix, nixpkgs, qrystal, nix-serve-ng, flake-utils, ... }@attrs:
    let pkgs = import nixpkgs { config.allowUnfree = true; };
    in {
      nixosConfigurations.miyo = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./miyo/configuration.nix ];
      };
      nixosConfigurations.naha = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./naha/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.hananawi = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./hananawi/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.rei = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./rei/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.cirno = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./cirno/configuration.nix agenix.nixosModules.default nix-serve-ng.nixosModules.default ];
      };
    } // flake-utils.lib.eachSystem flake-utils.lib.defaultSystems (system: let 
    pkgs = nixpkgs.legacyPackages.${system};in{
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [ nixfmt ];
      };
    });
}
