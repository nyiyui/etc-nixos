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
  };

  outputs = { self, agenix, nixpkgs, qrystal, ... }@attrs:
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
        modules = [ ./cirno/configuration.nix agenix.nixosModules.default ];
      };
    };
}
