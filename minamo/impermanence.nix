{
  specialArgs,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    specialArgs.impermanence.nixosModules.impermanence
    ../impermanent-root.nix
  ];

  impermanent-root.enable = true;

  # Ensure SSH keys are available before agenix runs
  age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib"
      "/etc/secureboot"
      "/etc/ssh"
    ];
    files = [ "/etc/machine-id" ];
    users.kiyurica = {
      directories = [
        "inaba"
        {
          directory = ".ssh";
          mode = "0700";
        }
        ".local/share/fish"
        ".thunderbird"
        ".config/syncthing"
        ".config/github-copilot"
        ".config/.copilot"
        ".config/joplin"
        ".config/joplin-desktop"
        ".codex"
        ".var/nixpak-app/org.signal.Signal"
        ".var/nixpak-app/org.mozilla.firefox"
        ".mozilla/firefox"
      ];
    };
  };
}
