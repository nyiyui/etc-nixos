{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.assr.nmea-static-gps-server;
  pythonScript = ./nmea_server.py;
in
{
  options.assr.nmea-static-gps-server = {
    enable = lib.mkEnableOption "NMEA static GPS server";

    latitude = lib.mkOption {
      type = lib.types.float;
      description = "Latitude in decimal degrees (negative = South).";
    };

    longitude = lib.mkOption {
      type = lib.types.float;
      description = "Longitude in decimal degrees (negative = West).";
    };

    altitude = lib.mkOption {
      type = lib.types.float;
      default = 0.0;
      description = "Altitude in metres above sea level.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 10110;
      description = "TCP port to listen on.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.avahi = {
      enable = true;
      publish.enable = true;
      extraServiceFiles.nmea-static = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">NMEA GPS (%h)</name>
          <service>
            <type>_nmea-0183._tcp</type>
            <port>${toString cfg.port}</port>
          </service>
        </service-group>
      '';
    };

    systemd.services.nmea-static-gps-server = {
      description = "NMEA static GPS server";
      after = [
        "network.target"
        "avahi-daemon.service"
      ];
      wants = [ "avahi-daemon.service" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        NMEA_LAT = toString cfg.latitude;
        NMEA_LON = toString cfg.longitude;
        NMEA_ALT = toString cfg.altitude;
        NMEA_PORT = toString cfg.port;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.python3}/bin/python3 ${pythonScript}";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
      };
    };
  };
}
