{ config, pkgs, ... }:
{
  imports = [ ../cloudflare-ddns-update ];

  services.cloudflare-ddns-update = {
    enable = true;
    authEmail = "kenxshibata@gmail.com";
    authKeyPath = config.age.secrets."cloudflare-ddns-update.api-key".path;
    recordName = "chocolate-lemon.nyiyui.ca";
    zoneID = "7407af8d2e784fbef1a2c13408a44685";
    sitename = "Chocolate-lemon";
    discordURIPath = config.age.secrets."cloudflare-ddns-update.discord-uri".path;
  };
  age.secrets."cloudflare-ddns-update.discord-uri" = {
    file = ../secrets/cloudflare-ddns-update.discord-uri.age;
    owner = "cloudflare-ddns-update";
    group = "root";
    mode = "400";
  };
  age.secrets."cloudflare-ddns-update.api-key" = {
    file = ../secrets/cloudflare-ddns-update.api-key.age;
    owner = "cloudflare-ddns-update";
    group = "root";
    mode = "400";
  };
}
