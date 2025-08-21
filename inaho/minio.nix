# minio instance for convind2
{ config, ... }:
{
  services.minio = {
    enable = true;
    listenAddress = "inaho.tailcbbed9.ts.net:9000";
    consoleAddress = "inaho.tailcbbed9.ts.net:9001";
    browser = true; # for testing
    dataDir = [ "-S /var/lib/minio/certs /var/lib/minio/data" ]; # workaround for nixos-24.11 (fixed in 25.05)
  };

  systemd.services.minio-cert-copy = {
    description = "Copy Tailscale certificates for MinIO";
    wantedBy = [ "minio.service" ];
    before = [ "minio.service" ];
    after = [ "provision-tailscale-cert.service" ];
    requires = [ "provision-tailscale-cert.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/minio/certs
      cp ${config.kiyurica.tailscale.cert.certPath}/${config.kiyurica.tailscale.cert.domain}.crt /var/lib/minio/certs/public.crt
      cp ${config.kiyurica.tailscale.cert.certPath}/${config.kiyurica.tailscale.cert.domain}.key /var/lib/minio/certs/private.key
      chown -R minio:minio /var/lib/minio/certs
      chmod 600 /var/lib/minio/certs/private.key
      chmod 644 /var/lib/minio/certs/public.crt
    '';
  };
}
