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
    assr.ocproxy = {
      enable = true;
      server = "dc-ext-gw.vpn.gatech.edu";
      # Since Fall 2026, connecting through the portal doesn't let us connect
      # to the gateway w/o another round of authn. Instead, we connect
      # directly to the gateway to not have to enter two OTPs.
      username = "kshibata6";
      password-file = ./secrets/gatech-vpn-password-${config.networking.hostName}.cred;
    };

    # TODO: implement kiyurica.gatech-vpn.sshProxyHosts
    hjem.users.kiyurica = {
      kiyurica.service-status = [
        {
          serviceName = "ocproxy.service";
          key = "VPN";
          propertyName = "ActiveState";
          propertyValue = "active";
        }
      ];
    };
  };
}
