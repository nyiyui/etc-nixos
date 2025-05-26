{ config, lib, ... }: 
{
  # see ./use-remote-builder.nix
  options.kiyurica.remote-builder.enable = lib.mkEnableOption "make this machine a remote builder";

  config = lib.mkIf config.kiyurica.remote-builder.enable {
    users.users.remote-build = {
      isNormalUser = true;
      description = "User to log in to for remote builds";
      openssh.authorizedKeys.keys = [];
    };
  
    nix.settings.trusted-users = [ "remote-build" ];
  };
}
