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
            allowedIPs = [ "10.42.0.0/16" ];
            #endpoint = "reimu.nyiyui.ca:42420";
            endpoint = "127.0.0.1:42420";
            persistentKeepalive = 30;
          }
        ];
      };
    };

    #systemd.services.reimu-choose = {
    #  enable = true;
    #  description = "reimu: choose udp2raw or direct";
    #  wantedBy = [ "multi-user.target" ];
    #  wants = [ "network-online.target" ];
    #  after = [ "network-online.target" ];
    #};

    systemd.services.reimu-ss-client = {
      enable = true;
      description = "reimu: shadowsocks client";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.writeShellScriptBin "reimu-ss-client.sh" ''
          ${pkgs.shadowsocks-rust}/bin/sslocal \
            -b '127.0.0.1:1080' \
            -s '10.42.0.1:56833' \
            -m 'chacha20-ietf-poly1305' \
            -k "$(cat /etc/nixos/reimu-ss-key)"
        ''}/bin/reimu-ss-client.sh";
      };
    };

    systemd.services.reimu-proxy = {
      enable = true;
      description = "udp2raw proxy for wg reimu";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.writeShellScriptBin "reimu-proxy.sh" ''
          ${udp2raw.packages.${pkgs.system}.default}/bin/udp2raw \
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
  }
])
