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
      "/etc/ssh"
    ];
    files = [ "/etc/machine-id" ];
    users.kiyurica = {
      directories = [
        "3d-spool"
        {
          directory = ".ssh";
          mode = "0700";
        }
        ".local/share/fish"
        ".config/syncthing"
      ];
    };
  };
}
