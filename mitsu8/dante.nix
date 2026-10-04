{ ... }:
{
  services.dante = {
    enable = true;
    config = ''
      internal.protocol: ipv4
      internal: tailscale0 port = 1080
      external: enp1s0

      socksmethod: none
      clientmethod: none

      client pass {
        from: 0.0.0.0/0 to: 0.0.0.0/0
      }
      socks pass {
        from: 0.0.0.0/0 to: 0.0.0.0/0
      }
    '';
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 1080 ];
}
