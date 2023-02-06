{ config, lib, pkgs, touhoukou, ... }:

(lib.mkMerge [
  (lib.mkIf (config.networking.hostName == "kumi") {
    networking.wireguard.interfaces.reimu.ips = [ "10.42.0.2/32" ];
  })
  {
    environment.systemPackages = [ pkgs.wireguard-tools ];
  
    networking.nat.enable = true;
    networking.nat.externalInterface = "eth0";
    networking.nat.internalInterfaces = [ "reimu" ];
    networking.wireguard.interfaces = {
      reimu = {
        privateKeyFile = "/etc/nixos/reimu-privkey";
        mtu = 1200;
        peers = [
          {
            publicKey = "y6cyueQS6Tv5uA1uoM5ce5RR+AuuaUw955/y+cr+QXc=";
            presharedKeyFile = "/etc/nixos/reimu-psk";
            allowedIPs = [ "10.42.0.0/16" ];
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
        ExecStart = "${pkgs.writeShellScriptBin "reimu-proxy.sh" ''
          ${touhoukou.packages.${pkgs.system}.udp2raw}/bin/udp2raw \
            -c -l127.0.0.1:42420 -r34.146.10.200:443 \
            -k "$(cat /etc/nixos/reimu-udp2raw-key)" \
            --raw-mode faketcp -a
        ''}/bin/reimu-proxy.sh";
        # TODO: run as non-root
        ProtectSystem = "strict";
        ProtectHome = "yes";
        PrivateTmp = "yes";
        #PrivateUsers = "yes";
        RemoveIPC = "yes";
      };
    };

    systemd.services.reimu-socks = {
      enable = true;
      description = "reimu: socks proxy over ssh";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.openssh}/bin/ssh -N -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -D 1081 kenxshibata@10.42.0.1";
        # TODO: run as non-root
        ProtectSystem = "strict";
        ProtectHome = "yes";
        PrivateTmp = "yes";
        PrivateUsers = "yes";
        DynamicUser = "yes";
        RemoveIPC = "yes";
      };
    };
  }
])
