{ config, lib, ... }:
let
  cfg = config.assr.tailscale;
in
{
  options.assr.tailscale.enable = lib.mkEnableOption "tailscale (auth key encrypted with systemd-creds, not agenix)";

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      port = 0;
      # services.tailscale.authKeyFile is typed as an absolute path, so this can't be
      # $CREDENTIALS_DIRECTORY; hardcode where systemd mounts LoadCredentialEncrypted for
      # the tailscaled-autoconnect.service unit instead.
      authKeyFile = "/run/credentials/tailscaled-autoconnect.service/tailscale-key";
    };
    # Generate with:
    #   run0 systemd-creds encrypt --name=tailscale-key key.txt secrets/tailscale-key-<hostname>.cred
    systemd.services.tailscaled-autoconnect.serviceConfig.LoadCredentialEncrypted =
      "tailscale-key:${./secrets/tailscale-key-${config.networking.hostName}.cred}";
    # Tie tailscaled to network-online.target (not multi-user.target).
    systemd.services.tailscaled = {
      wantedBy = lib.mkForce [ "network-online.target" ];
      before = lib.mkForce [ "network-online.target" ];
      # Trade-off: no remote support logs.
      environment.TS_NO_LOGS_NO_SUPPORT = "true";
      serviceConfig = {
        Nice = 5;
        CPUWeight = 20; # no CPUQuota: DERP-relayed traffic runs through this process
      };
    };
  };
}
