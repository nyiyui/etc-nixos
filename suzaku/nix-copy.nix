{
  pkgs,
  ...
}:
{
  # Dedicated trusted nix user for receiving store paths pushed from minamo via
  # `nix copy --to ssh-ng://nix-copy@suzaku`.  minamo's nix-copy-suzaku user
  # connects here; its SSH public key is read from the secrets directory.
  users.groups.nix-copy = { };
  users.users.nix-copy = {
    isSystemUser = true;
    group = "nix-copy";
    description = "Nix trusted user for receiving nix store paths from minamo";
    openssh.authorizedKeys.keyFiles = [ ../secrets/nix-copy-suzaku.pub ];
  };

  # nix-copy must be a trusted user so it can add paths to the nix store.
  nix.settings.trusted-users = [ "nix-copy" ];

  # Service that runs before nixos-upgrade to check whether minamo has already
  # pushed a pre-built suzaku NixOS configuration into the local store.
  # If the expected store path is already present (because minamo pushed it via
  # `nix copy --to`), nixos-upgrade will find it and skip the expensive local
  # build.  If not, nixos-upgrade falls back to building locally as usual.
  systemd.services.nixos-upgrade-check-minamo-build = {
    description = "Check whether minamo has pre-built suzaku's NixOS configuration";
    before = [ "nixos-upgrade.service" ];
    wantedBy = [ "nixos-upgrade.service" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
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
        echo "Store path is valid (minamo pre-built it); nixos-upgrade will use it directly."
      else
        echo "Store path not yet in local store; nixos-upgrade will build locally."
      fi
    '';
  };
}
