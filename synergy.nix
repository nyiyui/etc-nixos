{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kiyurica.synergy;
in
{
  options.kiyurica.synergy = {
    enable = lib.mkEnableOption "Synergy keyboard/mouse sharing";

    role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "client"
      ];
      description = "Whether this machine acts as a server or client";
    };

    serverAddress = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Address of the Synergy server (required for client)";
    };

    screenName = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Screen name for this machine in Synergy";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install barrier package (open-source fork of Synergy)
    environment.systemPackages = [ pkgs.barrier ];

    # Open firewall ports for Barrier/Synergy (default port 24800)
    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.role == "server") [ 24800 ];

    # Configure systemd user service for Barrier server
    systemd.user.services.barrier-server = lib.mkIf (cfg.role == "server") {
      description = "Barrier Server (Synergy fork)";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.barrier}/bin/barriers --no-tray --debug INFO --name ${cfg.screenName} --enable-crypto --address :24800";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };

    # Configure systemd user service for Barrier client
    systemd.user.services.barrier-client = lib.mkIf (cfg.role == "client") {
      description = "Barrier Client (Synergy fork)";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.barrier}/bin/barrierc --no-tray --debug INFO --name ${cfg.screenName} --enable-crypto ${cfg.serverAddress}:24800";
        Restart = "always";
        RestartSec = 3;
      };
    };
  };
}
