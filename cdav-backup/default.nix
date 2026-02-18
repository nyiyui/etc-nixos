{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.assr.services.cdav-backup;
  python = pkgs.python3.withPackages (p: [ p.caldav ]);
in
{
  # NOTE: assr ≤ あさせのせせらぎ instead of kiyurica for reusability
  options.assr.services.cdav-backup = {
    enable = lib.mkEnableOption "export CalDAV calendars to local .ics files";

    url = lib.mkOption {
      type = lib.types.str;
      description = "CalDAV base URL (sets CALDAV_URL).";
    };

    usernameFile = lib.mkOption {
      type = lib.types.path;
      description = "Encrypted systemd credential file for CalDAV username";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "Encrypted systemd credential file for CalDAV password";
    };

    destination = lib.mkOption {
      type = lib.types.str;
      description = "Destination directory for exported .ics files";
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "systemd timer OnCalendar value.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.cdav-backup = {
      description = "export CalDAV calendars";
      serviceConfig = {
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${cfg.destination}";
        ExecStart = "${python}/bin/python ${./export.py}";

        Environment = [
          "CALDAV_URL=${cfg.url}"
          "DESTINATION=${cfg.destination}"
        ];

        ReadWritePaths = [ cfg.destination ];

        LoadCredential = [
          "username:${cfg.usernameFile}"
        ];
        LoadCredentialEncrypted = [
          "password:${cfg.passwordFile}"
        ];

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
        SystemCallFilter = [ "@system-service" ];
      };
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    systemd.timers.cdav-backup = {
      timerConfig.OnCalendar = lib.mkDefault cfg.onCalendar;
      timerConfig.Persistent = true;
      wantedBy = [ "timers.target" ];
    };
  };
}
