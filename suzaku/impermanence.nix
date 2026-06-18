{
  specialArgs,
  config,
  ...
}:
{
  imports = [
    specialArgs.impermanence.nixosModules.impermanence
  ];

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib"
      "/etc/NetworkManager/system-connections"
      "/etc/ssh"
      config.microvm.stateDir
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
        ".local/share/prusa-slicer"
        ".local/share/containers"
        ".var/nixpak-app/io.github.alainm23.planify"
        ".var/nixpak-app/org.mozilla.firefox"
        ".mozilla/firefox"
        ".var/nixpak-app/org.mozilla.Thunderbird"
        ".thunderbird"
        ".var/nixpak-app/org.signal.Signal"
        # ".var/nixpak-app/org.strawberrymusicplayer.strawberry"
        ".config/syncthing"
        ".config/Moonlight Game Streaming Project"
        ".cache/Moonlight Game Streaming Project"
        ".config/github-copilot"
        ".config/.copilot"
        ".codex"
        ".config/dpt"
        ".gemini"
      ];
    };
  };
}
