{ config, pkgs, lib, ... }: let
  uuid = "66a918a9-4711-4093-886d-77a1a946dc47";
in {
  # TODO: eduroam configuration not done!
  options.kiyurica.eduroam = {
    enable = lib.mkEnableOption "eduroam configuration";
    interface = lib.mkOption {
      type = lib.types.str;
      default = "wlp0s20f3"; # default interface for eduroam
      description = "Network interface to use for eduroam.";
    };
  };
  config = lib.mkIf config.kiyurica.eduroam.enable {
    networking.networkmanager.ensureProfiles.secrets.entries = [{
      file = config.age.secrets.eduroam-client-cert.file;
      key = "eduroam-client-cert";
      matchUuid = uuid;
      matchIface = config.kiyurica.eduroam.interface;
      matchType = "802-11-wireless";
      matchId = "eduroam";
    }];
    networking.networkmanager.ensureProfiles.profiles.eduroam = {
      connection.type = "802-11-wireless";
      connection.uuid = uuid;
      connection.id = "eduroam";
      wifi.mode = "infrastructure";
      wifi.ssid = "eduroam";
    };

    age.secrets.eduroam-client-cert = {
      file = ./secrets/eduroam-client-cert-${config.networking.hostName}.p12.age;
      owner = "nyiyui";
      group = "nyiyui";
    };
  };
}
