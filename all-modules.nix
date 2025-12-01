{
  # all modules which have an explicit "enable" option
  imports = [
    ./sway.nix
    ./niri
    ./gtkgreet.nix
    ./tailscale.nix
    ./tailscale-cert.nix
    ./autoUpgrade-git.nix
    ./reimu2.nix
    ./remote-builder.nix
    ./use-remote-builder.nix
    ./kdeconnect.nix
    ./laptop.nix
    ./power-efficiency.nix
    ./displaylink.nix
    ./eduroam
    ./synergy.nix
    ./aiden.nix
    ./nerd-dictation
    ./gatech-vpn.nix
    ./ocproxy.nix
    ./ollama.nix
    ./proxy-server.nix
    ./firefox.nix
  ];
}
