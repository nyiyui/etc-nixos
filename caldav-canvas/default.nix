{ config, pkgs, lib, ... }:
let
  pythonEnv = pkgs.python3.withPackages (ps: [ ps.caldav ps.icalendar ]);
  script = ./canvas_to_caldav.py;
in
{
  options.kiyurica.caldav-canvas = {
    enable = lib.mkEnableOption "Canvas-to-CalDAV sync service";
    caldav-url = lib.mkOption {
      type = lib.types.str;
      description = "CalDAV server URL";
    };
    caldav-username = lib.mkOption {
      type = lib.types.str;
      description = "CalDAV username";
    };
    tasklist-name = lib.mkOption {
      type = lib.types.str;
      description = "Optional CalDAV task list/calendar name";
    };
    uid-filter = lib.mkOption {
      type = lib.types.str;
      description = "Regex to include only VEVENTs whose UID matches";
      default = "assignment";
    };
    url-file = lib.mkOption {
      type = lib.types.str;
      description = "Path to a systemd credential file containing the Canvas .ics URL";
    };
    password-file = lib.mkOption {
      type = lib.types.str;
      description = "Path to a systemd credential file containing the CalDAV password";
    };
  };

  config = lib.mkIf config.kiyurica.caldav-canvas.enable (
    let
      args = []
        ++ [ "--caldav-url" config.kiyurica.caldav-canvas.caldav-url ]
        ++ [ "--caldav-username" config.kiyurica.caldav-canvas.caldav-username ]
        ++ [ "--tasklist-name" config.kiyurica.caldav-canvas.tasklist-name ]
        ++ [ "--uid-filter" config.kiyurica.caldav-canvas.uid-filter ];
    in
    {
      systemd.services.caldav-canvas = {
        description = "Sync Canvas .ics to CalDAV VTODOs";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
          script = ''
            set -eu
            ICS_FILE="$STATE_DIRECTORY/canvas.ics"
            ${lib.optionalString (config.kiyurica.caldav-canvas.url-file != null) ''
              URL=$(cat "$CREDENTIALS_DIRECTORY/canvas-url")
              ${pkgs.curl}/bin/curl -fsSL "$URL" -o "$ICS_FILE"
            ''}
            ${lib.optionalString (config.kiyurica.caldav-canvas.password-file != null) ''
              PW=$(cat "$CREDENTIALS_DIRECTORY/caldav-password")
              export CALDAV_PASSWORD="$PW"
            ''}
            ${pythonEnv}/bin/python ${script} ${lib.escapeShellArgs args} --ics-path "$ICS_FILE"
          '';

        serviceConfig = {
          Type = "oneshot";
          StateDirectory = "caldav-canvas";
          LoadCredentialEncrypted = [
            "canvas-url:${config.kiyurica.caldav-canvas.url-file}"
            "caldav-password:${config.kiyurica.caldav-canvas.password-file}"
          ];

          # Hardening
          AmbientCapabilities = "";
          CapabilityBoundingSet = "";
          DynamicUser = "yes";
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
          RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
          RestrictNamespaces = "yes";
          RestrictRealtime = "true";
          RestrictSUIDSGID = "true";
          SystemCallArchitectures = "native";
          SystemCallFilter = [ "@system-service" ];
        };
      };
    }
  );
}
