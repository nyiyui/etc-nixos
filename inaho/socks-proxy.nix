{ pkgs, ... }:
{
  # Forward local port 1080 to the SOCKS5 proxy on mitsu8, so that
  # socks5://inaho:1080 behaves the same as socks5://mitsu8.tailcbbed9.ts.net:1080.
  systemd.sockets.socks-proxy-forward = {
    description = "Socket for SOCKS5 proxy forward to mitsu8";
    listenStreams = [ "1080" ];
    wantedBy = [ "sockets.target" ];
  };

  systemd.services.socks-proxy-forward = {
    description = "SOCKS5 proxy forward to mitsu8";
    requires = [ "socks-proxy-forward.socket" ];
    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd mitsu8.tailcbbed9.ts.net:1080";
      Restart = "on-failure";
    };
  };

  networking.firewall.allowedTCPPorts = [ 1080 ];
}
