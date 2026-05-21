{ self, pkgs, ... }:

{
  imports = [
    ./host-network.nix
    ./host-service.nix
  ];

  environment.systemPackages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.dev-vm
    self.packages.${pkgs.stdenv.hostPlatform.system}.dev-vm-ssh
    self.packages.${pkgs.stdenv.hostPlatform.system}.dev-vm-start
  ];
}
