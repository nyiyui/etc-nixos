{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    qrystal.url = "github:nyiyui/qrystal/next1";
    qrystal.inputs.nixpkgs.follows = "nixpkgs";
    qrystal.inputs.flake-utils.follows = "flake-utils";
    qrystal2.url = "github:nyiyui/qrystal/next2goal";
    qrystal2.inputs.nixpkgs.follows = "nixpkgs";
    qrystal2.inputs.flake-utils.follows = "flake-utils";
    jks.url = "github:nyiyui/jks";
    jks.inputs.nixpkgs.follows = "nixpkgs";
    jks.inputs.flake-utils.follows = "flake-utils";
    seekback-server.url = "github:nyiyui/seekback-server";
    seekback-server.inputs.nixpkgs.follows = "nixpkgs";
    seekback-server.inputs.flake-utils.follows = "flake-utils";
    touhoukou.url = "github:nyiyui/touhoukou";
    touhoukou.inputs.nixpkgs.follows = "nixpkgs";
    touhoukou.inputs.flake-utils.follows = "flake-utils";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    deploy-rs.url = "github:serokell/deploy-rs";
    seekback.url = "github:nyiyui/seekback";
    seekback.inputs.nixpkgs.follows = "nixpkgs";
    seekback.inputs.flake-utils.follows = "flake-utils";
    niri.url = "github:sodiboo/niri-flake";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";
    nixos-wsl.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, agenix, nixpkgs, qrystal, qrystal2, flake-utils, niri
    , deploy-rs, ... }@attrs:
    let
      pkgs = import nixpkgs { config.allowUnfree = true; };
      host-deploy = name: {
        hostname = "${name}.nyiyui.ca";
        #sshUser = "miyamizu-sync"; # for chocolate-lemon
        user = "root";
        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.${name};
        };
      };
    in rec {
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
      nixosConfigurations.chocolate-lemon = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules =
          [ ./chocolate-lemon/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.leaside = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./leaside/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.chikusa = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./chikusa/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.minato = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./minato/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.yagoto = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = attrs;
        modules = [ ./yagoto/configuration.nix agenix.nixosModules.default ];
      };
      nixosConfigurations.sekisho2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./sekisho2/configuration.nix ];
      };
      images.yagoto = nixosConfigurations.yagoto.config.system.build.sdImage;
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    } // flake-utils.lib.eachSystem flake-utils.lib.defaultSystems (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nixfmt-rfc-style
            deploy-rs.packages.${system}.default
            (python3.withPackages (p: [ p.pyserial ]))
          ];
        };
      });
}
