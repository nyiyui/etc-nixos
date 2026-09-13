{ pkgs, ... }:
{
  # Forward local port 1080 to the SOCKS5 proxy on tk2-246-32584, so that
  # socks5://inaho:1080 behaves the same as socks5://tk2-246-32584.tailcbbed9.ts.net:1080.
  systemd.sockets.socks-proxy-forward = {
    description = "Socket for SOCKS5 proxy forward to tk2-246-32584";
    listenStreams = [ "1080" ];
    wantedBy = [ "sockets.target" ];
  };

  systemd.services.socks-proxy-forward = {
    description = "SOCKS5 proxy forward to tk2-246-32584";
    requires = [ "socks-proxy-forward.socket" ];
    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd tk2-246-32584.tailcbbed9.ts.net:1080";
      Restart = "on-failure";
    };
  };

  networking.firewall.allowedTCPPorts = [ 1080 ];
}
