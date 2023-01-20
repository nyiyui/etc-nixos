{ config, lib, pkgs, udp2raw, ... }:

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
            #endpoint = "reimu.nyiyui.ca:42420";
            endpoint = "127.0.0.1:42420";
            persistentKeepalive = 30;
          }
        ];
      };
    };

    systemd.services.reimu-proxy = {
      enable = true;
      description = "udp2raw proxy for wg reimu";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${udp2raw.packages.${pkgs.system}.default}/bin/udp2raw -c -l127.0.0.1:42420 -r34.146.10.200:443  -k 'kyunkyun' --raw-mode faketcp -a";
      };
    };
  }
])
