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
    kiyurica.ocproxy = {
      enable = true;
      server = "vpn.gatech.edu";
      gateway = "DC Gateway";
      username = "kshibata6";
      password-file = ./secrets/gatech-vpn-password-${config.networking.hostName}.cred;
    };

    home-manager.users.kiyurica = lib.mkIf config.kiyurica.home-manager.enable {
      programs.ssh = {
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
  };
}
