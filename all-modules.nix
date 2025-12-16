{
  # all modules which have an explicit "enable" option to prevent unintended enables for ease of debugging etc
  imports = [
    ./sway.nix
    ./niri
    ./gtkgreet.nix
    ./tailscale.nix
    ./tailscale-cert.nix
    ./autoUpgrade-git.nix
    ./reimu2.nix
    ./laptop.nix
    ./power-efficiency.nix
    ./displaylink.nix
    ./eduroam
    ./aiden.nix
    ./gatech-vpn.nix
    ./ocproxy.nix
    ./ollama.nix
    ./proxy-server.nix
    ./keepassxc.nix
    ./sandbox-dev.nix
  ];
}
