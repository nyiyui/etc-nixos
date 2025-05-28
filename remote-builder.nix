{ config, lib, ... }:
{
  # see ./use-remote-builder.nix
  options.kiyurica.remote-builder.enable = lib.mkEnableOption "make this machine a remote builder";

  config = lib.mkIf config.kiyurica.remote-builder.enable {
    users.users.remote-build = {
      isNormalUser = true;
      description = "User to log in to for remote builds";
      openssh.authorizedKeys.keys = [
        # NOTE: eva-00 and friends are not NixOS machines, and therefore have to have SSH keys synced to them by hand
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPtA1YLDpuFOdXJRowvZEVx1X0M1YUDmo0Eaxjq5WSY2 root@misaki"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ9Z/KUpNuN0LYa3eczVJkMwjHULKbvu8Ii7P/BgPK52 root@mitsu8"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDy5lcb0I4CjFMc9SCr2ZJYTqfnInabxDPS+AHcUSTiH root@suzaku"
      ];
    };

    nix.settings.trusted-users = [ "remote-build" ];
  };
}
