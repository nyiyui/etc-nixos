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

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib"
      "/etc/secureboot"
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
    ];
    files = [ "/etc/machine-id" ];
    users.kiyurica = {
      directories = [
        "inaba"
        "3d-spool"
        {
          directory = ".ssh";
          mode = "0700";
        }
        ".local/share/fish"
        ".local/share/log-window-titles"
        ".local/PrusaSlicer"
        ".local/share/prusa-slicer"
        ".var/nixpak-app/io.github.alainm23.planify"
        ".var/nixpak-app/org.mozilla.firefox"
        ".mozilla/firefox"
        ".var/nixpak-app/org.mozilla.Thunderbird"
        ".thunderbird"
        ".var/nixpak-app/org.signal.Signal"
        # ".var/nixpak-app/org.strawberrymusicplayer.strawberry"
        ".config/syncthing"
        ".config/github-copilot"
        ".config/.copilot"
        ".config/joplin"
        ".config/joplin-desktop"
        ".codex"
        ".config/dpt"
        ".config/unity3d"
        ".config/unityhub"
        "Unity"
      ];
    };
  };
}
