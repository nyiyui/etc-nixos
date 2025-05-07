{ config, lib, ... }:
{
  # NOTE: make sure you configure the peer on the ER605.
  options.kiyurica.networks.er605.enable = lib.mkEnableOption "ER605 wireguard network";
  options.kiyurica.networks.er605.address = lib.mkOption {
    type = lib.types.str;
    description = "this device's network IPv4 address in CIDR format";
  };

  config = lib.mkIf config.kiyurica.networks.er605.enable {
    networking.wireguard.interfaces.er605 = {
      ips = [ config.kiyurica.networks.er605.address ];
      privateKeyFile = config.age.secrets.er605-privkey.path;
      peers = [
        {
          publicKey = "f2Q0N7rAHME0NQCnOWmhD6yHAtNzGM7GKiqfe+39rEo=";
          allowedIPs = [
            "10.8.0.0/16" # ER605 LAN
            "10.9.0.0/24" # ER605 wireguard network
          ];
          endpoint = "128.61.106.120:24134";
          persistentKeepalive = 30;
        }
      ];
    };

    age.secrets.er605-privkey = {
      file = ./secrets/er605-${config.networking.hostName}.privkey.age;
      mode = "400";
    };
  };
}
