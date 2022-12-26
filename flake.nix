{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-22.11;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    qrystal.url = "github:nyiyui/qrystal/lightmusic";
  };

  outputs = { self, nixpkgs, qrystal, ... }@attrs: let
    pkgs = import nixpkgs { config.allowUnfree = true; };
  in {
    nixosConfigurations.kumi = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [
        ./kumi/configuration.nix
        qrystal.nixosModules.${system}.node
        ({ ... }: {
          qrystal.services.node = {
            enable = true;
          };
        })
      ];
    };
    nixosConfigurations.miyo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ ./miyo/configuration.nix ];
    };
  };
}
