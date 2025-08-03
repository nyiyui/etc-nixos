{ config, lib, ... }:
{
  options.kiyurica.networks.eduroam.enable = lib.mkEnableOption "GT eduroam";

  config = lib.mkIf config.kiyurica.networks.eduroam.enable {
    networking.networkmanager.ensureProfiles.environmentFiles = [
      config.age.secrets.eduroam-env.path
    ];
    networking.networkmanager.ensureProfiles.profiles.eduroam = {
      "802-1x" = {
        ca-cert = "${./usertrustrsaca.cer}";
        client-cert = config.age.secrets.eduroam-client-cert.path;
        domain-suffix-match = "lawn.gatech.edu";
        eap = "tls;";
        identity = "kshibata6@gatech.edu";
        private-key = config.age.secrets.eduroam-client-cert.path;
        private-key-password = "$EDUROAM_PRIVATE_KEY_PASSWORD";
      };
      connection = {
        id = "eduroam 3";
        type = "wifi";
        uuid = "a22a03f6-ddb5-455c-80f2-024cfc52266a";
      };
      ipv4 = {
        method = "auto";
      };
      ipv6 = {
        addr-gen-mode = "stable-privacy";
        method = "auto";
      };
      proxy = { };
      wifi = {
        mode = "infrastructure";
        ssid = "eduroam";
      };
      wifi-security = {
        key-mgmt = "wpa-eap";
      };
    };

    age.secrets.eduroam-client-cert = {
      file = ./client-cert-${config.networking.hostName}.p12.age;
      mode = "400";
    };
    age.secrets.eduroam-env = {
      file = ./secrets-${config.networking.hostName}.env.age;
      mode = "400";
    };
  };
}
