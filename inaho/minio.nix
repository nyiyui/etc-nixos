# minio instance for convind2
# untested!
{ ... }:
{
  services.minio = {
    enable = true;
    listenAddress = "inaho.tailcbbed9.ts.net:9000";
    consoleAddress = "inaho.tailcbbed9.ts.net:9001";
    browser = false; # no need (yet)
  };
}
