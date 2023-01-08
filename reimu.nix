{ config, lib, pkgs, ... }:

(lib.mkMerge [
  (lib.mkIf (config.networking.hostName == "kumi") {
    networking.wireguard.interfaces.reimu.ips = [ "10.42.0.2/32" ];
  })
  {
    environment.systemPackages = [ pkgs.wireguard-tools ];
  
    networking.nat.enable = true;
    networking.nat.externalInterface = "eth0";
    networking.nat.internalInterfaces = [ "reimu" ];
    networking.firewall = {
      allowedUDPPorts = [ 28607 ];
    };
    networking.wireguard.interfaces = {
      reimu = {
        privateKeyFile = "/etc/nixos/reimu-privkey";
        peers = [
          {
            publicKey = "y6cyueQS6Tv5uA1uoM5ce5RR+AuuaUw955/y+cr+QXc=";
            presharedKeyFile = "/etc/nixos/reimu-psk";
            allowedIPs = [
              "10.42.0.0/16"
              #"136.144.57.121/32"
              #"0.0.0.0/0"
            ];
            endpoint = "reimu.nyiyui.ca:42420";
            persistentKeepalive = 30;
          }
        ];
      };
    };
  }
])
