{ config, lib, pkgs, ... }:
let
  cfg = config.kiyurica.synergy;
in
{
  options.kiyurica.synergy = {
    enable = lib.mkEnableOption "Synergy keyboard/mouse sharing";
    
    role = lib.mkOption {
      type = lib.types.enum [ "server" "client" ];
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
    
    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically start Synergy";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install synergy package
    environment.systemPackages = [ pkgs.synergy ];
    
    # Open firewall ports for Synergy (default port 24800)
    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.role == "server") [ 24800 ];
    
    # Configure Synergy server
    services.synergy.server = lib.mkIf (cfg.role == "server") {
      enable = true;
      address = "0.0.0.0:24800";
      screenName = cfg.screenName;
      autoStart = cfg.autoStart;
    };
    
    # Configure Synergy client
    services.synergy.client = lib.mkIf (cfg.role == "client") {
      enable = true;
      serverAddress = cfg.serverAddress;
      screenName = cfg.screenName;
      autoStart = cfg.autoStart;
    };
  };
}
