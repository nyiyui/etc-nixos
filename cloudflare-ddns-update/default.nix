{ config, lib, pkgs, ... }:
let cfg = config.services.cloudflare-ddns-update;
in {
  options.services.cloudflare-ddns-update = with lib;
    with types; {
      enable = mkEnableOption "Cloudflare DDNS updater";
      authEmail = mkOption {
        type = str;
        description = "The email used to login 'https://dash.cloudflare.com'";
      };
      authMethod = mkOption {
        type = enum [ "global" "token" ];
        default = "token";
        description = ''
          Set to "global" for Global API Key or "token" for Scoped API Token'';
      };
      authKeyPath = mkOption {
        type = path;
        description = "Path to API Token or Global API Key";
      };
      zoneID = mkOption {
        type = str;
        description = ''Can be found in the "Overview" tab of your domain'';
      };
      recordName = mkOption {
        type = str;
        description = "Which DNS record to update";
      };
      ttl = mkOption {
        type = int;
        default = 60;
        description = "DNS TTL in seconds";
      };
      proxy = mkOption {
        type = bool;
        default = false;
        description = "Let Cloudflare proxy the record or not";
      };
      sitename = mkOption {
        type = str;
        description = "Title of site";
      };
      slackChannel = mkOption {
        type = nullOr str;
        default = null;
        description = "Slack Channel to send to";
      };
      slackURI = mkOption {
        type = nullOr str;
        default = null;
        description = "URI for Slack Webhook";
      };
      discordURIPath = mkOption {
        type = nullOr str;
        default = null;
        description = "Path to URI for Discord Webhook";
      };
    };
  config = lib.mkIf cfg.enable {
    users.groups.cloudflare-ddns-update = { };
    users.users.cloudflare-ddns-update = {
      isSystemUser = true;
      description = "For cloudflare-ddns-update.service";
      group = "cloudflare-ddns-update";
    };
    systemd.services.cloudflare-ddns-update = {
      environment = {
        AUTH_EMAIL = cfg.authEmail;
        AUTH_METHOD = cfg.authMethod;
        AUTH_KEY_PATH = cfg.authKeyPath;
        ZONE_IDENTIFIER = cfg.zoneID;
        RECORD_NAME = cfg.recordName;
        TTL = toString cfg.ttl;
        PROXY = toString cfg.proxy;
        SITENAME = cfg.sitename;
        SLACKCHANNEL = toString cfg.slackChannel;
        SLACKURI = toString cfg.slackURI;
        DISCORDURI_PATH = toString cfg.discordURIPath;
      };
      serviceConfig = {
        ExecStart = ./updater.sh;
        Type = "oneshot";
        User = "cloudflare-ddns-update";
      };
    };
  };
}
