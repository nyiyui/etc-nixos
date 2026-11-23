{
  assr,
  config,
  lib,
  ...
}:
let
  cfg = config.assr.eduroam;
  dir = "/run/eduroam";
  client-cert = "${dir}/client-cert.p12";
  env = "${dir}/env";
  # systemd-creds validates the name embedded at encrypt time against the credential ID, so
  # these must match the names in the option descriptions below.
  client-cert-name = "eduroam-client-cert-${config.networking.hostName}";
  private-key-password-name = "eduroam-private-key-password-${config.networking.hostName}";
in
{
  # Replaces assr.nixosModules.eduroam, which takes the same options as agenix secrets instead.
  disabledModules = [ "${assr}/eduroam" ];

  options.assr.eduroam = {
    enable = lib.mkEnableOption "GT eduroam NetworkManager connection (secrets via systemd-creds, not agenix)";
    client-cert-cred = lib.mkOption {
      description = "Client certificate encrypted with systemd-creds, named eduroam-client-cert-<hostname>";
      type = lib.types.path;
      default = ./secrets/eduroam-client-cert-${config.networking.hostName}.cred;
    };
    private-key-password-cred = lib.mkOption {
      description = "Client certificate passphrase encrypted with systemd-creds, named eduroam-private-key-password-<hostname>";
      type = lib.types.path;
      default = ./secrets/eduroam-private-key-password-${config.networking.hostName}.cred;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.eduroam-creds = {
      description = "Install eduroam credentials for NetworkManager and wpa_supplicant";
      script = ''
        install -m 0440 -g wpa_supplicant "$CREDENTIALS_DIRECTORY/${client-cert-name}" ${client-cert}
        printf 'EDUROAM_PRIVATE_KEY_PASSWORD=%s\n' "$(cat "$CREDENTIALS_DIRECTORY/${private-key-password-name}")" >${env}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredentialEncrypted = [
          "${client-cert-name}:${cfg.client-cert-cred}"
          "${private-key-password-name}:${cfg.private-key-password-cred}"
        ];
        # Group= makes systemd chown the RuntimeDirectory to root:wpa_supplicant; UMask=
        # keeps ${env} root-only (the group bit is only for the cert, set explicitly above).
        Group = "wpa_supplicant";
        UMask = "0077";
        RuntimeDirectory = "eduroam";
        RuntimeDirectoryMode = "0750";
        RuntimeDirectoryPreserve = "yes";
      };
    };

    systemd.services.wpa_supplicant = {
      wants = [ "eduroam-creds.service" ]; # allow wpa_supplicant to proceed if eduroam fails
      after = [ "eduroam-creds.service" ];
      # ProtectSystem=strict plus RootDirectory=/run/wpa_supplicant means the P12 is only
      # reachable inside the unit's root if it is bind-mounted in.
      serviceConfig.BindReadOnlyPaths = [ "-${client-cert}" ];
      restartTriggers = [ cfg.client-cert-cred ];
    };

    systemd.services.NetworkManager-ensure-profiles = {
      wants = [ "eduroam-creds.service" ];
      after = [ "eduroam-creds.service" ];
      restartTriggers = [ cfg.private-key-password-cred ];
    };

    networking.networkmanager.ensureProfiles.environmentFiles = [ env ];
    networking.networkmanager.ensureProfiles.profiles.eduroam = {
      "802-1x" = {
        ca-cert = "${assr}/eduroam/usertrustrsaca.cer";
        client-cert = client-cert;
        domain-suffix-match = "lawn.gatech.edu";
        eap = "tls;";
        identity = "kshibata6@gatech.edu";
        private-key = client-cert;
        private-key-password = "$EDUROAM_PRIVATE_KEY_PASSWORD";
      };
      connection = {
        id = "eduroam (GT)";
        type = "wifi";
        uuid = "a22a03f6-ddb5-455c-80f2-024cfc52266a";
      };
      ipv4.method = "auto";
      ipv6 = {
        addr-gen-mode = "stable-privacy";
        method = "auto";
      };
      proxy = { };
      wifi = {
        mode = "infrastructure";
        ssid = "eduroam";
      };
      wifi-security.key-mgmt = "wpa-eap";
    };
  };
}
