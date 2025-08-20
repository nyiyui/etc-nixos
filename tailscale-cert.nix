{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kiyurica.tailscale.cert;
in
{
  options.kiyurica.tailscale.cert = {
    enable = lib.mkEnableOption "provision tailscale certificate";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Tailscale domain to provision certificate for";
      default = "${config.networking.hostName}.tailcbbed9.ts.net";
    };

    certPath = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/tailscale-cert";
      description = "Path where the certificate files will be stored";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.provision-tailscale-cert = {
      description = "Provision Tailscale certificate";
      after = [
        "tailscaled.service"
        "network-online.target"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        ExecStart = pkgs.writeShellScript "provision-tailscale-cert" ''
          set -euo pipefail

          CERT_PATH="${cfg.certPath}"
          DOMAIN="${cfg.domain}"

          mkdir -p "$CERT_PATH"

          echo "Provisioning Tailscale certificate for $DOMAIN"

          ${pkgs.tailscale}/bin/tailscale cert \
            --cert-file "$CERT_PATH/$DOMAIN.crt" \
            --key-file "$CERT_PATH/$DOMAIN.key" \
            "$DOMAIN"

          chown -R root:root "$CERT_PATH"
          chmod 600 "$CERT_PATH"/*.key
          chmod 644 "$CERT_PATH"/*.crt

          echo "Certificate provisioned successfully to $CERT_PATH"
        '';
      };
    };
  };
}
