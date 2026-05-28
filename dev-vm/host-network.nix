{ pkgs, ... }:
{
  # Setuid wrapper so virtiofsd can run as root (needed for --sandbox=chroot to
  # work correctly: root can write a full uid_map 0:0:65536 so files owned by
  # uid 0 appear as root in the guest instead of the overflow UID 65534).
  # Restricted to the kiyurica group; not world-executable.
  security.wrappers.virtiofsd = {
    source = "${pkgs.virtiofsd}/bin/virtiofsd";
    owner = "root";
    group = "kiyurica";
    permissions = "u+rx,g+rx,o-rwx";
    setuid = true;
  };
  # Allow forwarding between VM bridge and the outside.
  boot.kernel.sysctl."net.ipv4.ip_forward" = "1";

  # Bridge used by all dev VMs. TAP interfaces are attached per-launch by
  # the dev-vm wrapper script; this just provides the persistent L2 segment
  # and the host-side gateway IP.
  networking.bridges.vm0.interfaces = [ ];
  networking.interfaces.vm0.ipv4.addresses = [
    {
      address = "10.100.0.1";
      prefixLength = 24;
    }
  ];

  # Tell NetworkManager to leave vm0 and any vm-* TAPs alone.
  networking.networkmanager.unmanaged = [
    "interface-name:vm0"
    "interface-name:vm-*"
  ];

  # DHCP for VMs. bind-interfaces ensures dnsmasq only listens on vm0
  # and does not conflict with systemd-resolved on other interfaces.
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "vm0";
      bind-interfaces = true;
      dhcp-range = "10.100.0.10,10.100.0.254,1h";
      # All dev VMs share the same NixOS closure → same machine-id → same
      # DUID → same client-ID. Ignore it and assign leases by MAC instead.
      dhcp-ignore-clid = true;
    };
  };

  # NAT masquerade for the VM subnet. Using extraCommands so the rule
  # works regardless of which physical interface (WiFi or ethernet) is
  # the current default route.
  networking.firewall.extraCommands = ''
    iptables -t nat -A POSTROUTING -s 10.100.0.0/24 -j MASQUERADE
    iptables -A FORWARD -i vm0 -j ACCEPT
    iptables -A FORWARD -o vm0 -m state --state ESTABLISHED,RELATED -j ACCEPT
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D POSTROUTING -s 10.100.0.0/24 -j MASQUERADE || true
    iptables -D FORWARD -i vm0 -j ACCEPT || true
    iptables -D FORWARD -o vm0 -m state --state ESTABLISHED,RELATED -j ACCEPT || true
  '';

  # Allow VMs to reach dnsmasq (DNS + DHCP) on the host, but nothing else.
  networking.firewall.interfaces.vm0.allowedUDPPorts = [
    53 # DNS
    67 # DHCP
  ];
  networking.firewall.interfaces.vm0.allowedTCPPorts = [
    53 # DNS
  ];
}
