{ config, lib, pkgs, touhoukou, ... }:

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
    networking.wireguard.interfaces = {
      kimihenokore = {
        privateKeyFile = "/etc/nixos/wireguard-privkey";
        peers = [
          {
            publicKey = "EYxF76Poj9O1mV3bhvQ1UXdewvHcI+dDi70f3qmGOS0=";
            presharedKeyFile = "/etc/nixos/wireguard-psk";
            allowedIPs = [ "10.5.0.0/24" ];
            endpoint = "127.0.0.1:28607";
            persistentKeepalive = 30;
          }
        ];
      };
    };

    systemd.services.kimihenokore-proxy = {
      enable = true;
      description = "udp2raw proxy for wg kimihenokore";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.writeShellScriptBin "kimihenokore-proxy.sh" ''
          ${touhoukou.packages.${pkgs.system}.udp2raw}/bin/udp2raw \
            -c -l127.0.0.1:28607 -r34.130.187.64:3389 \
            -k "$(cat /etc/nixos/kimihenokore-udp2raw-key)" \
            --raw-mode faketcp -a
        ''}/bin/kimihenokore-proxy.sh";
        # TODO: run as non-root
        ProtectSystem = "strict";
        ProtectHome = "yes";
        PrivateTmp = "yes";
        #PrivateUsers = "yes";
        RemoveIPC = "yes";
      };
    };
  }
])
