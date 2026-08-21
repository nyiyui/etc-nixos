{ ... }:
{
  services.motioneye.enable = true;

  # motionEye web UI (port 8765), tailscale-only (matches ollama.nix / syncthing.nix pattern)
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 8765 ];
}
