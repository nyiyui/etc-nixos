{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    qrystal.url = "github:nyiyui/qrystal/next1";
    touhoukou.url = "github:nyiyui/touhoukou";
    touhoukou.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nix-serve-ng.url = github:aristanetworks/nix-serve-ng;
    flake-utils.url = github:numtide/flake-utils;
    deploy-rs.url = "github:serokell/deploy-rs";
    seekback.url = "github:nyiyui/seekback";
    seekback.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, agenix, nixpkgs, qrystal, nix-serve-ng, flake-utils, deploy-rs, ... }@attrs:
  let
    pkgs = import nixpkgs { config.allowUnfree = true; };
    host-deploy = name: {
          hostname = "${name}.msb.q.nyiyui.ca";
          #sshUser = "miyamizu-sync"; # for chocolate-lemon
          user = "root";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos
              self.nixosConfigurations.${name};
          };
        };
    in {
      nixosConfigurations.naha = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./naha/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.mitsu8 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./mitsu8/configuration.nix agenix.nixosModules.default ];
      };
      deploy.nodes.mitsu8 = host-deploy "mitsu8";
      nixosConfigurations.hinanawi = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./hinanawi/configuration.nix agenix.nixosModules.default ];
      };
      deploy.nodes.hinanawi = host-deploy "hinanawi";
      nixosConfigurations.chocolate-lemon = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./chocolate-lemon/configuration.nix agenix.nixosModules.default ];
      };
      deploy.nodes.chocolate-lemon = host-deploy "chocolate-lemon";
      nixosConfigurations.kotiya = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./kotiya/configuration.nix agenix.nixosModules.default nix-serve-ng.nixosModules.default ];
      };
      nixosConfigurations.minato = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./minato/configuration.nix agenix.nixosModules.default ];
      };
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    } // flake-utils.lib.eachSystem flake-utils.lib.defaultSystems (system: let 
    pkgs = nixpkgs.legacyPackages.${system};in{
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nixfmt
          deploy-rs.packages.${system}.default
          (python3.withPackages (p: [ p.pyserial ]))
        ];
      };
    });
}
