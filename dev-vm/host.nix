{ self, pkgs, ... }:

{
  imports = [
    ./host-network.nix
    ./host-service.nix
  ];

  environment.systemPackages = [
    self.packages.${pkgs.system}.dev-vm
    self.packages.${pkgs.system}.dev-vm-ssh
    self.packages.${pkgs.system}.dev-vm-start
  ];
}
