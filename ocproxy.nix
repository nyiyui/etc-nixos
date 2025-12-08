{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./home-manager.nix ];

  options.kiyurica.ocproxy.enable = lib.mkEnableOption "GlobalProtect VPN via proxy";
  options.kiyurica.ocproxy.user =
    with lib;
    with types;
    mkOption {
      description = "Linux user the VPN proxy will run as";
      default = "ocproxy";
      type = str;
    };
  options.kiyurica.ocproxy.group =
    with lib;
    with types;
    mkOption {
      description = "Linux group the VPN proxy will run as";
      default = "ocproxy";
      type = str;
    };
  options.kiyurica.ocproxy.server =
    with lib;
    with types;
    mkOption {
      description = "VPN server";
      example = "vpn.gatech.edu";
      type = str;
    };
  options.kiyurica.ocproxy.gateway =
    with lib;
    with types;
    mkOption {
      description = "gateway to use";
      example = "DC Gateway";
      type = str;
    };
  options.kiyurica.ocproxy.username =
    with lib;
    with types;
    mkOption {
      description = "username for VPN";
      example = "gburdell3";
      type = str;
    };
  options.kiyurica.ocproxy.password-file =
    with lib;
    with types;
    mkOption {
      description = ''
        path to file containing the password that is encrypted for systemd

        For example, use `run0 systemd-creds encrypt --name=password password.txt password.cred` to generate the file.
      '';
      type = path;
    };
  options.kiyurica.ocproxy.socks-port =
    with lib;
    with types;
    mkOption {
      description = "run SOCKS5 proxy server on this port";
      type = port;
      default = 11080;
    };

  config = lib.mkIf config.kiyurica.ocproxy.enable {
    kiyurica.home-manager.enable = true;
    users.groups.${config.kiyurica.ocproxy.group} = { };
    users.users.${config.kiyurica.ocproxy.user} = {
      isSystemUser = true;
      description = "Georgia Tech VPN";
      group = config.kiyurica.ocproxy.group;
    };
    systemd.services.ocproxy = {
      description = "Georgia Tech VPN";
      path = with pkgs; [
        openconnect
        ocproxy
      ];
      enableStrictShellChecks = true;
      serviceConfig = {
        LoadCredentialEncrypted = "password:${config.kiyurica.ocproxy.password-file}";
        User = config.kiyurica.ocproxy.user;

        CapabilityBoundingSet = "";
        LockPersonality = "true";
        MemoryDenyWriteExecute = "yes";
        NoNewPrivileges = "true";
        PrivateDevices = "true";
        PrivateTmp = true;
        PrivateUsers = "true";
        ProtectClock = "true";
        ProtectControlGroups = "true";
        ProtectHome = "true";
        ProtectHostname = "true";
        ProtectKernelLogs = "true";
        ProtectKernelModules = "true";
        ProtectKernelTunables = "true";
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = "true";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
        ];
        RestrictNamespaces = "yes";
        RestrictRealtime = "true";
        RestrictSUIDSGID = "true";
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
        ];
      };
      script = ''
        set -eu

        export PASSWORD_FILE_PATH="$CREDENTIALS_DIRECTORY/password"
        { cat "$PASSWORD_FILE_PATH"; echo 'push1'; } | \
        openconnect \
          --verbose \
          --protocol=gp \
          --user='${config.kiyurica.ocproxy.username}' \
          --authgroup='${config.kiyurica.ocproxy.gateway}' \
          --script-tun --script 'ocproxy -D ${builtins.toString config.kiyurica.ocproxy.socks-port}' \
          '${config.kiyurica.ocproxy.server}'
      '';
    };
    home-manager.users.kiyurica =
      { config, pkgs, ... }:
      {
        kiyurica.service-status = [
          {
            serviceName = "ocproxy.service";
            key = "VPN";
            propertyName = "ActiveState";
            propertyValue = "active";
          }
        ];
        programs.waybar.settings.mainBar."custom/VPN" = {
          on-click = "/run/current-system/sw/bin/systemctl start ocproxy.service";
          on-click-right = "/run/current-system/sw/bin/systemctl stop ocproxy.service";
        };
      };
  };
}
