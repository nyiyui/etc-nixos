{
  config,
  lib,
  caldav-canvas-gradescope,
  ...
}:
let
  cfg = config.kiyurica.caldav-canvas-gradescope;
in
{
  options.kiyurica.caldav-canvas-gradescope = {
    enable = lib.mkEnableOption "sync Canvas/Gradescope assignments to CalDAV";
    credFile = lib.mkOption {
      type = lib.types.path;
      description = "path to credential file containing a shell script sourced before the script, made using systemd-creds(1) using the name `caldav-canvas-gradescope-env`";
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.services.caldav-canvas-gradescope = {
      description = "sync Canvas/Gradescope assignments to CalDAV";
      script = ''
        set -eu
        source "$CREDENTIALS_DIRECTORY/caldav-canvas-gradescope-env"
        ${caldav-canvas-gradescope.packages.default}/bin/caldav-canvas-gradescope
      '';
      serviceConfig = {
        LoadCredentialEncrypted = [ "caldav-canvas-gradescope-env:${cfg.credFile}" ];
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
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };
    systemd.timers.caldav-canvas-gradescope = {
      timerConfig.OnCalendar = lib.mkDefault "daily";
      timerConfig.Persistent = true;
      wantedBy = [ "timers.target" ];
    };
  };
}
