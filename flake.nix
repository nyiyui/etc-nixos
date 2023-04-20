{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    qrystal.url = "github:nyiyui/qrystal/main";
    touhoukou.url = github:nyiyui/touhoukou;
    touhoukou.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = github:ryantm/agenix;
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, qrystal, ... }@attrs: let
    pkgs = import nixpkgs { config.allowUnfree = true; };
  in {
    nixosConfigurations.kumi = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [./kumi/configuration.nix ];
    };
    nixosConfigurations.miyo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ ./miyo/configuration.nix ];
    };
    nixosConfigurations.naha = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ ./naha/configuration.nix ];
    };
    nixosConfigurations.hananawi = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ ./hananawi/configuration.nix ];
    };
  };
}
