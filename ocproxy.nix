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
  options.kiyurica.ocproxy.twoFactor =
    with lib;
    with types;
    mkOption {
      description = ''
        Fixed answer to send to the VPN's second-factor prompt, e.g. "push1" for a Duo push.

        If null, ask interactively via `vpn-connect`, which prompts in your terminal and
        passes the response to the service via a transient systemd manager environment
        variable. Use a fixed value on
        hosts with no one around to answer that prompt (e.g. minamo, other servers).
      '';
      type = nullOr str;
      default = null;
      example = "push1";
    };

  config = lib.mkIf config.kiyurica.ocproxy.enable {
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
        systemd # for systemd-ask-password
      ];
      enableStrictShellChecks = true;
      serviceConfig = {
        LoadCredentialEncrypted = "password:${config.kiyurica.ocproxy.password-file}";
        PassEnvironment = "OCPROXY_TWO_FACTOR";
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
        set -euo pipefail

        export PASSWORD_FILE_PATH="$CREDENTIALS_DIRECTORY/password"
        pw_value="$(cat "$PASSWORD_FILE_PATH")"
        ${
          if config.kiyurica.ocproxy.twoFactor != null then
            "two_factor=${lib.escapeShellArg config.kiyurica.ocproxy.twoFactor}"
          else
            ''
              two_factor="${OCPROXY_TWO_FACTOR-}"
              if [ -z "$two_factor" ]; then
                echo "No second-factor response was provided. Start via vpn-connect or set kiyurica.ocproxy.twoFactor." >&2
                exit 1
              fi
            ''
        }

        printf '%s\n%s\n' "$pw_value" "$two_factor" | \
        openconnect \
          --verbose \
          --protocol=gp \
          --user='${config.kiyurica.ocproxy.username}' \
          --authgroup='${config.kiyurica.ocproxy.gateway}' \
          --script-tun --script 'ocproxy -D ${builtins.toString config.kiyurica.ocproxy.socks-port}' \
          '${config.kiyurica.ocproxy.server}'
      '';
    };
    hjem.users.kiyurica = {
      kiyurica.service-status = [
        {
          serviceName = "ocproxy.service";
          key = "VPN";
          propertyName = "ActiveState";
          propertyValue = "active";
        }
      ];
      xdg.config.files."fish/config.fish".text = ''
        function vpn-connect
          set -l two_factor (systemd-ask-password --timeout=0 'Georgia Tech VPN 2FA:')
          if test -z "$two_factor"
            echo "No second-factor response was provided." >&2
            return 1
          end

          printf '%s\n' "$two_factor" | run0 sh -euc '
            IFS= read -r two_factor
            systemctl set-environment OCPROXY_TWO_FACTOR="$two_factor"
            trap "systemctl unset-environment OCPROXY_TWO_FACTOR" EXIT
            systemctl start ocproxy.service
          '
        end
      '';
    };
  };
}
