{ config, lib, ... }: {
  options.kiyurica.tailscale.enable = lib.mkEnableOption "tailscale";

  config = lib.mkIf config.kiyurica.tailscale.enable {
    services.tailscale = {
      enable = true;
      port = 0;
      authKeyFile = config.age.secrets.tailscale-key.path;
      authKeyParameters = {
        baseURL = "https://headscale.etc.kiyuri.ca";
      };
    };
    age.secrets.tailscale-key = {
      file = ./secrets/tailscale-key-${config.networking.hostName}.age;
      mode = "400";
    };
  };
}
