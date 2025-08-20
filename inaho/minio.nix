# minio instance for convind2
{ config, ... }:
{
  services.minio = {
    enable = true;
    listenAddress = "inaho.tailcbbed9.ts.net:9000";
    consoleAddress = "inaho.tailcbbed9.ts.net:9001";
    browser = true; # for testing
    dataDir = [ "-S ${config.kiyurica.tailscale.cert.certPath} /var/lib/minio/data" ]; # workaround for nixos-24.11 (fixed in 25.05)
  };
}
