{
  pkgs,
  ...
}:
{
  # Dedicated trusted nix user that suzaku can SSH into to pull pre-built store
  # paths via `nix copy --from ssh-ng://nix-copy-suzaku@minamo`.
  # suzaku's nix-copy user connects here using the key in secrets/nix-copy-suzaku.pub.
  users.groups.nix-copy-suzaku = { };
  users.users.nix-copy-suzaku = {
    isSystemUser = true;
    group = "nix-copy-suzaku";
    description = "Nix trusted user allowing suzaku to pull pre-built store paths";
    openssh.authorizedKeys.keyFiles = [ ../secrets/nix-copy-suzaku.pub ];
  };

  # nix-copy-suzaku must be a trusted user so suzaku can query and copy store
  # paths from minamo's nix daemon.
  nix.settings.trusted-users = [ "nix-copy-suzaku" ];

  # Builds suzaku's NixOS configuration and keeps the closure in minamo's store
  # so that suzaku can pull it on demand before nixos-upgrade runs.
  systemd.services.build-suzaku = {
    description = "Build suzaku's NixOS configuration on minamo";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "nix-copy-suzaku";
    };
    script = ''
      set -euo pipefail

      # NOTE: this flake reference must match the one in suzaku/nix-copy.nix.
      FLAKE="github:nyiyui/etc-nixos#nixosConfigurations.suzaku.config.system.build.toplevel"

      echo "Building suzaku's NixOS configuration..."
      RESULT=$(${pkgs.nix}/bin/nix build --no-link --print-out-paths "$FLAKE")

      echo "Build complete: $RESULT"
      echo "suzaku can now pull this closure via: nix copy --from ssh-ng://nix-copy-suzaku@minamo.local $RESULT"
    '';
  };

  # Run every Thursday evening so the build is ready before suzaku's
  # Friday 02:30 nixos-upgrade window.
  systemd.timers.build-suzaku = {
    description = "Timer for pre-building suzaku's NixOS configuration on minamo";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Thu *-*-* 22:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
