{ self, pkgs, ... }:

{
  imports = [
    ./host-network.nix
    ./host-notify.nix
    ./host-service.nix
  ];

  environment.systemPackages = [
    self.packages.${pkgs.stdenv.hostPlatform.system}.dev-vm-enter
  ];
}
