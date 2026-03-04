{
  config,
  pkgs,
  ...
}:
let
  # Build a static known_hosts file using minamo's host key from the repo,
  # avoiding TOFU and ensuring the connection is to the correct host.
  minamoKnownHosts = pkgs.writeText "minamo-known-hosts" "minamo.local ${builtins.readFile ../minamo/ssh_host_ed25519_key.pub}";
in
{
  # Dedicated trusted nix user for pulling pre-built store paths from minamo.
  # This user's SSH public key is authorized on minamo's nix-copy-suzaku account.
  users.groups.nix-copy = { };
  users.users.nix-copy = {
    isSystemUser = true;
    group = "nix-copy";
    description = "Nix trusted user for pulling pre-built store paths from minamo";
  };

  # nix-copy must be a trusted user so it can add paths to the nix store.
  nix.settings.trusted-users = [ "nix-copy" ];

  # SSH private key used by suzaku's nix-copy user to authenticate to minamo's
  # nix-copy-suzaku user when pulling store paths.
  age.secrets.nix-copy-suzaku-ssh-key = {
    file = ../secrets/nix-copy-suzaku.id_ed25519.age;
    owner = "nix-copy";
    mode = "400";
  };

  # Runs before nixos-upgrade: pulls suzaku's pre-built NixOS closure from
  # minamo via `nix copy --from ssh-ng://nix-copy-suzaku@minamo`.
  # If minamo is unreachable or hasn't built the closure yet, this service exits
  # successfully so nixos-upgrade falls back to building locally as usual.
  systemd.services.nixos-upgrade-copy-from-minamo = {
    description = "Pull suzaku's pre-built NixOS closure from minamo before nixos-upgrade";
    before = [ "nixos-upgrade.service" ];
    wantedBy = [ "nixos-upgrade.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "nix-copy";
    };
    script = ''
      set -euo pipefail

      # NOTE: this flake reference must match the one in minamo/build-suzaku.nix.
      FLAKE="github:nyiyui/etc-nixos#nixosConfigurations.suzaku.config.system.build.toplevel"

      echo "Evaluating suzaku NixOS flake to find expected store path..."
      TARGET=$(${pkgs.nix}/bin/nix eval --raw "''${FLAKE}.outPath" 2>/dev/null) || {
        echo "Could not evaluate flake; nixos-upgrade will build locally."
        exit 0
      }
      echo "Expected store path: $TARGET"

      if ${pkgs.nix}/bin/nix-store --check-validity "$TARGET" 2>/dev/null; then
        echo "Store path already present locally; nothing to copy."
        exit 0
      fi

      # Pull the closure from minamo using the repo's known host key.
      SSH_KEY="${config.age.secrets.nix-copy-suzaku-ssh-key.path}"
      export NIX_SSHOPTS="-i $SSH_KEY -o StrictHostKeyChecking=yes -o UserKnownHostsFile=${minamoKnownHosts}"

      echo "Pulling closure from minamo..."
      ${pkgs.nix}/bin/nix copy --from "ssh-ng://nix-copy-suzaku@minamo.local" "$TARGET" || {
        echo "Could not pull from minamo (it may be unavailable or the build is not ready); nixos-upgrade will build locally."
        exit 0
      }

      echo "Successfully pulled $TARGET from minamo."
    '';
  };
}
