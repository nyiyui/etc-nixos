{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    qrystal.url = "github:nyiyui/qrystal/next1";
    qrystal2.url = "github:nyiyui/qrystal/next2goal";
    touhoukou.url = "github:nyiyui/touhoukou";
    touhoukou.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    nix-serve-ng.url = "github:aristanetworks/nix-serve-ng";
    flake-utils.url = "github:numtide/flake-utils";
    deploy-rs.url = "github:serokell/deploy-rs";
    seekback.url = "github:nyiyui/seekback";
    seekback.inputs.nixpkgs.follows = "nixpkgs";
    niri.url = "github:sodiboo/niri-flake";
  };

  outputs = { self, agenix, nixpkgs, qrystal, qrystal2, nix-serve-ng, flake-utils, niri
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
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./headless.nix
          ./base.nix
          ({ ... }: {
            config = {
              sdImage.compressImage = false;
              time.timeZone = "America/New_York";
              i18n.defaultLocale = "en_CA.UTF-8";

              users.users.root.initialHashedPassword = "$y$j9T$Oy.M1VzXQXFNXhLpsqbi..$lkvdnMD9WTyKc5ek7Dx3XoeyqKGtvEAuVhabHNyyz0D";
              system = {
                stateVersion = "24.05";
              };
              networking = {
                wireless.enable = false;
              };
              environment.systemPackages = with pkgs; [
              ];
            };
          })
        ];
      };
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
