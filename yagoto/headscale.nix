{ ... }:
let port = 39254;
in {
  services.headscale = {
    enable = true;
    inherit port;
    settings = {
      server_url = "https://headscale.etc.kiyuri.ca";
      listen_addr = "localhost:${builtins.toString port}";
      tls_cert_path = null;
      tls_key_path = null;
      # TODO: TS2021 Noise Protocol
      prefixes.v4 = "10.9.0.0/16";
      dns.base_domain = "tailnet.kiyuri.ca";
    };
  };
  services.caddy = {
    enable = true;
    virtualHosts."headscale.etc.kiyuri.ca" = {
      extraConfig = ''
        reverse_proxy http://localhost:${builtins.toString port}
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
