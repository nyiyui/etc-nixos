{
  # all modules which have an explicit "enable" option
  imports = [
    ./er605.nix
    ./sway.nix
    ./gtkgreet.nix
    ./tailscale.nix
    ./tailscale-cert.nix
    ./autoUpgrade-git.nix
    ./reimu2.nix
    ./claude-code.nix
    ./remote-builder.nix
    ./use-remote-builder.nix
    ./kdeconnect.nix
    ./laptop.nix
    ./displaylink.nix
    ./eduroam
  ];
}
