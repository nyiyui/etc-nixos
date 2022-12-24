{ config, lib, pkgs, ... }:

(lib.mkMerge [
  (lib.mkIf (config.networking.hostName == "kumi") {
    networking.wireguard.interfaces.kimihenokore.ips = [ "10.5.0.93/32" ];
  })
  (lib.mkIf (config.networking.hostName == "miyo") {
    networking.wireguard.interfaces.kimihenokore.ips = [ "10.5.0.94/32" ];
  })
  {
    environment.systemPackages = [ pkgs.wireguard-tools ];
  
    networking.nat.enable = true;
    networking.nat.externalInterface = "eth0";
    networking.nat.internalInterfaces = [ "kimihenokore" ];
    networking.firewall = {
      allowedUDPPorts = [ 28607 ];
    };
    networking.wireguard.interfaces = {
      kimihenokore = {
        privateKeyFile = "/etc/nixos/wireguard-privkey";
        peers = [
          {
            publicKey = "EYxF76Poj9O1mV3bhvQ1UXdewvHcI+dDi70f3qmGOS0=";
            presharedKeyFile = "/etc/nixos/wireguard-psk";
            allowedIPs = [ "10.5.0.0/24" ];
            endpoint = "kimihenokore.nyiyui.ca:28607";
            persistentKeepalive = 30;
          }
        ];
      };
    };
  }
])
