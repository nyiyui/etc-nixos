{ config, lib, ... }:
{
  options.kiyurica.tailscale.enable = lib.mkEnableOption "tailscale";

  config = lib.mkIf config.kiyurica.tailscale.enable {
    services.tailscale = {
      enable = true;
      port = 0;
      authKeyFile = config.age.secrets.tailscale-key.path;
    };
    age.secrets.tailscale-key = {
      file = ./secrets/tailscale-key-${config.networking.hostName}.age;
      mode = "400";
    };
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
