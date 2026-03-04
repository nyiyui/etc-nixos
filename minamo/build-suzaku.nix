{
  config,
  pkgs,
  ...
}:
{
  # Dedicated trusted nix user for building suzaku's NixOS configuration and
  # pushing the result to suzaku via `nix copy --to ssh-ng://nix-copy@suzaku`.
  users.groups.nix-copy-suzaku = { };
  users.users.nix-copy-suzaku = {
    isSystemUser = true;
    group = "nix-copy-suzaku";
    description = "Nix build/copy user for pushing suzaku builds to suzaku";
    home = "/var/lib/nix-copy-suzaku";
    createHome = true;
  };

  # nix-copy-suzaku must be a trusted user so it can build derivations and
  # interact with the nix daemon.
  nix.settings.trusted-users = [ "nix-copy-suzaku" ];

  # SSH private key used by nix-copy-suzaku to connect to suzaku's nix-copy user.
  age.secrets.nix-copy-suzaku-ssh-key = {
    file = ../secrets/nix-copy-suzaku.id_ed25519.age;
    owner = "nix-copy-suzaku";
    mode = "400";
  };

  # Builds suzaku's NixOS configuration and pushes the full closure to suzaku
  # using `nix copy --to ssh-ng://nix-copy@suzaku`.  suzaku's nixos-upgrade.service
  # then finds the store paths already present and skips the local build.
  systemd.services.build-suzaku = {
    description = "Build suzaku's NixOS configuration and push it to suzaku";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "nix-copy-suzaku";
    };
    script = ''
      set -euo pipefail

      # Ensure SSH directory exists for known_hosts persistence (TOFU).
      mkdir -p /var/lib/nix-copy-suzaku/.ssh
      chmod 700 /var/lib/nix-copy-suzaku/.ssh

      # Pass the SSH private key to nix copy via NIX_SSHOPTS.
      # StrictHostKeyChecking=accept-new accepts new host keys on first connection
      # and verifies them on subsequent connections (trust-on-first-use).
      SSH_KEY="${config.age.secrets.nix-copy-suzaku-ssh-key.path}"
      KNOWN_HOSTS="/var/lib/nix-copy-suzaku/.ssh/known_hosts"
      export NIX_SSHOPTS="-i $SSH_KEY -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$KNOWN_HOSTS"

      # NOTE: this flake reference must match the one in suzaku/nix-copy.nix.
      FLAKE="github:nyiyui/etc-nixos#nixosConfigurations.suzaku.config.system.build.toplevel"

      echo "Building suzaku's NixOS configuration..."
      RESULT=$(${pkgs.nix}/bin/nix build --no-link --print-out-paths "$FLAKE")

      echo "Pushing closure to suzaku: $RESULT"
      ${pkgs.nix}/bin/nix copy --to "ssh-ng://nix-copy@suzaku.local" "$RESULT"

      echo "Successfully pushed suzaku's NixOS build to suzaku."
    '';
  };

  # Run every Thursday evening so that suzaku's Friday 02:30 nixos-upgrade
  # finds the store paths already present.
  systemd.timers.build-suzaku = {
    description = "Timer for building and pushing suzaku's NixOS configuration";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Thu *-*-* 22:00:00";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
