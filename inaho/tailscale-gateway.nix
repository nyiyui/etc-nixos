{ pkgs, ... }:
let
  lanIf = "enp1s0";
  exitNode = "mitsu8";
  clientsFile = "/var/lib/tailscale-gateway/clients";
in
{
  networking.nftables.enable = true;

  networking.nat = {
    enable = true;
    externalInterface = "tailscale0";
    internalInterfaces = [ lanIf ];
  };

  # Only forward/NAT traffic from explicitly allowed MAC addresses
  networking.nftables.tables."tailscale-gateway" = {
    family = "inet";
    content = ''
      set clients {
        type ether_addr
      }

      chain forward {
        type filter hook forward priority filter; policy drop;
        ct state { established, related } accept
        iifname "${lanIf}" ether saddr @clients oifname "tailscale0" accept
      }
    '';
  };

  systemd.services.tailscale-gateway-clients = {
    description = "Load tailscale-gateway's allowed MAC addresses";
    after = [ "nftables.service" ];
    requires = [ "nftables.service" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = clientsFile;
    path = [ pkgs.nftables ];
    script = ''
      set -eu
      nft flush set inet tailscale-gateway clients
      while IFS= read -r mac; do
        [ -z "$mac" ] && continue
        nft add element inet tailscale-gateway clients "{ $mac }"
      done < ${clientsFile}
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
  };

  services.tailscale.extraSetFlags = [
    "--exit-node=${exitNode}"
    "--exit-node-allow-lan-access"
  ];
}
