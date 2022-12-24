{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs;
    home-manager.url = github:nix-community/home-manager;
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = { self, nixpkgs, ... }@attrs: let
    pkgs = import nixpkgs { config.allowUnfree = true; };
  in {
    nixosConfigurations.kumi = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ ./configuration.nix ];
    };
    nixosConfigurations.miyo = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = attrs;
      modules = [ ./configuration-miyo.nix ];
    };
  };
}
