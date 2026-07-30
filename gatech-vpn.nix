{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kiyurica.gatech-vpn.enable = lib.mkEnableOption "Georgia Tech VPN via proxy";

  options.kiyurica.gatech-vpn.sshProxyHosts =
    with lib;
    with types;
    mkOption {
      description = "Host patterns for SSH that should use the VPN SOCKS proxy";
      type = listOf str;
      default = [
        "*.pace.gatech.edu !login-ice.pace.gatech.edu"
      ];
    };

  config = lib.mkIf config.kiyurica.gatech-vpn.enable {
    age.secrets."gatech-vpn-password.cred" = {
      file = ./secrets/gatech-vpn-password-${config.networking.hostName}.cred.age;
      owner = config.kiyurica.ocproxy.user;
      mode = "400";
    };
    kiyurica.ocproxy = {
      enable = true;
      server = "vpn.gatech.edu";
      gateway = "DC Gateway";
      username = "kshibata6";
      password-file = config.age.secrets."gatech-vpn-password.cred".path;
    };

    home-manager.users.kiyurica.programs.ssh = {
      enable = true;
      settings = builtins.listToAttrs (
        map (h: {
          name = h;
          value = {
            ProxyCommand = "nc -X 5 -x 127.0.0.1:${builtins.toString config.kiyurica.ocproxy.socks-port} %h %p";
          };
        }) config.kiyurica.gatech-vpn.sshProxyHosts
      );
    };
  };
}
