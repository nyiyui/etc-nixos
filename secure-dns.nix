{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.kiyurica.secure-dns.enable = lib.mkEnableOption "DNSCrypt";

  config = lib.mkIf config.kiyurica.secure-dns.enable {
    services.dnscrypt-proxy = {
      enable = true;
    };
    # TODO: exempt capnet-assist from using DNSCrypt
  };
}
