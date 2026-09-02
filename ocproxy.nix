{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.assr.ocproxy.enable = lib.mkEnableOption "GlobalProtect VPN via proxy";
  options.assr.ocproxy.user =
    with lib;
    with types;
    mkOption {
      description = "Linux user the VPN proxy will run as";
      default = "ocproxy";
      type = str;
    };
  options.assr.ocproxy.group =
    with lib;
    with types;
    mkOption {
      description = "Linux group the VPN proxy will run as";
      default = "ocproxy";
      type = str;
    };
  options.assr.ocproxy.server =
    with lib;
    with types;
    mkOption {
      description = "VPN server";
      example = "ni-ext-gw.vpn.gatech.edu";
      type = str;
    };
  options.assr.ocproxy.username =
    with lib;
    with types;
    mkOption {
      description = "username for VPN";
      example = "gburdell3";
      type = str;
    };
  options.assr.ocproxy.password-file =
    with lib;
    with types;
    mkOption {
      description = ''
        path to file containing the password that is encrypted for systemd

        For example, use `run0 systemd-creds encrypt --name=password password.txt password.cred` to generate the file.
      '';
      type = path;
    };
  options.assr.ocproxy.socks-port =
    with lib;
    with types;
    mkOption {
      description = "run SOCKS5 proxy server on this port";
      type = port;
      default = 11080;
    };
  options.assr.ocproxy.otp-fifo =
    with lib;
    with types;
    mkOption {
      description = "path where a FIFO will be created. Type your OTP (or \"push\" if you have Duo) here to connect.";
      type = path;
      default = "/run/ocproxy-otp";
    };

  config = lib.mkIf config.assr.ocproxy.enable {
    users.groups.${config.assr.ocproxy.group} = { };
    users.users.${config.assr.ocproxy.user} = {
      isSystemUser = true;
      description = "Georgia Tech VPN";
      group = config.assr.ocproxy.group;
    };
    systemd.sockets.ocproxy = {
      description = "OpenConnect VPN proxy socket for OTP";
      socketConfig = {
        ListenFIFO = config.assr.ocproxy.otp-fifo;
        SocketMode = "0600";
        SocketUser = "root";
      };
      wantedBy = [ "multi-user.target" ];
    };
    systemd.services.ocproxy = {
      description = "OpenConnect VPN proxy";
      path = with pkgs; [
        openconnect
        ocproxy
        systemd # for systemd-ask-password
      ];
      enableStrictShellChecks = true;
      serviceConfig = {
        LoadCredentialEncrypted = "password:${config.assr.ocproxy.password-file}";
        User = config.assr.ocproxy.user;
        StandardInput = "socket";
        # otherwise stdout and stderr default to socket D:
        StandardOutput = "journal";
        StandardError = "journal";

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
          "AF_UNIX"
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

        read -r OTP
        export PASSWORD_FILE_PATH="$CREDENTIALS_DIRECTORY/password"
        { cat "$PASSWORD_FILE_PATH"; echo; echo "$OTP"; } | \
        openconnect \
          --verbose \
          --protocol=gp \
          --user=${lib.escapeShellArg config.assr.ocproxy.username} \
          --script-tun --script 'ocproxy -D ${builtins.toString config.assr.ocproxy.socks-port}' \
          ${lib.escapeShellArg config.assr.ocproxy.server}
      '';
    };
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "ocproxy-provide-otp" ''
        tee ${lib.escapeShellArg config.assr.ocproxy.otp-fifo} > /dev/null
      '')
    ];
  };
}
