# TODO: move all uses of reimu.nix to reimu2.nix
{ config, lib, ... }: {
  # NOTE: make sure you configure the peer on Reimu
  options.kiyurica.networks.reimu.enable = lib.mkEnableOption "reimu wireguard";
  options.kiyurica.networks.reimu.address = lib.mkOption {
    type = lib.types.str;
    description = "this device's network IPv4 address in CIDR format";
  };

  config = lib.mkIf config.kiyurica.networks.reimu.enable {
    networking.wireguard.interfaces.reimu = {
      ips = [ config.kiyurica.networks.reimu.address ];
      privateKeyFile = config.age.secrets.reimu-privkey.path;
      peers = [{
        publicKey = "y6cyueQS6Tv5uA1uoM5ce5RR+AuuaUw955/y+cr+QXc=";
        allowedIPs = [ "10.42.0.1/32" ];
        endpoint = "reimu.dev.kiyuri.ca:42420";
        persistentKeepalive = 30;
        dynamicEndpointRefreshRestartSeconds =
          10; # dns resolver (dnscrypt?) is flaky on mitsu8
      }];
    };

    age.secrets.reimu-privkey = {
      file = ./secrets/reimu-${config.networking.hostName}.privkey.age;
      mode = "400";
    };
  };
}
