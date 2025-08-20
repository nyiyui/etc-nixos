# minio instance for convind2
{ config, ... }:
{
  services.minio = {
    enable = true;
    listenAddress = "inaho.tailcbbed9.ts.net:9000";
    consoleAddress = "inaho.tailcbbed9.ts.net:9001";
    browser = true; # for testing
    certificatesDir = config.kiyurica.tailscale.cert.certPath;
  };
}
