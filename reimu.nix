{ config, lib, pkgs, touhoukou, ... }:

let
  cfg = config.reimu;
in {
  options.reimu = with lib; with types; {
    enable = mkEnableOption "reimu VPN";
    endpoint = mkOption {
      type = str;
      default = "reimu.nyiyui.ca:42420";
      description = "endpoint for wireguard";
    };
    address = mkOption {
      type = str;
      description = "address for wireguard";
    };
    udp2raw = mkOption {
      type = (submodule {
        options = {
          enable = mkEnableOption "use udp2raw to circumvent UDP blocks";
          addr = mkOption {
            type = str;
            default = "127.0.0.42:42420";
            description = "bind address for udp2raw and endpoint address for wireguard";
          };
        };
      });
    };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      systemd.services.reimu-proxy = {
        enable = true;
        description = "udp2raw proxy for wg reimu";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.writeShellScriptBin "reimu-proxy.sh" ''
            ${touhoukou.packages.${pkgs.system}.udp2raw}/bin/udp2raw \
              -c -l${cfg.udp2raw.addr} -r34.146.10.200:443 \
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
              endpoint = if cfg.udp2raw.enable then cfg.udp2raw.addr else cfg.endpoint;
              persistentKeepalive = 30;
            }
          ];
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
  ];
}
