{ config, lib, pkgs, ... }:

{
  #networking = {
  #  nameservers = [ "127.0.0.1" "::1" ];
  #};
  services.unbound = {
    enable = true;
    resolveLocalQueries = false;
    settings = {
      server = {
        interface = [ "127.0.0.1" "::1" ];
      };
      forward-zone = [
        {
          name = ".";
          forward-addr = "1.1.1.1@853#cloudflare-dns.com";
        }
        {
          name = "example.org.";
          forward-addr = [
            "1.1.1.1@853#cloudflare-dns.com"
            "1.0.0.1@853#cloudflare-dns.com"
          ];
        }
      ];
    };
  };
}
