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
      "/root/.ssh"
    ];
    files = [ "/etc/machine-id" ];
    users.kiyurica = {
      directories = [
        {
          directory = ".ssh";
          mode = "0700";
        }
        ".local/share/fish"
        ".mozilla/firefox"
        ".thunderbird"
        ".config/syncthing"
      ];
    };
  };
}
