{ assr, ... }: {
  # all modules which have an explicit "enable" option to prevent unintended enables for ease of debugging etc
  imports = [
    ./niri
    ./gtkgreet.nix
    ./autoUpgrade-git.nix
    ./laptop.nix
    ./power-efficiency.nix
    ./displaylink.nix
    ./gatech-vpn.nix
    ./ocproxy.nix
    ./sandbox-dev.nix
    assr.nixosModules.eduroam
  ];
}
