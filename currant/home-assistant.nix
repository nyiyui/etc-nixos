{ pkgs, ... }:
{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      "zha"
      "default_config"
      "met"
    ];
    config = {
      # Configures Home Assistant and its Zigbee integration via the UI
      default_config = { };
    };
    extraConfig = ''
      automation: !include automations.yaml
      script: !include scripts.yaml
      scene: !include scenes.yaml
    '';
  };

  # Ensure writable files exist for the UI to manage
  systemd.tmpfiles.rules = [
    "f /var/lib/hass/automations.yaml 0644 hass hass - -"
    "f /var/lib/hass/scripts.yaml 0644 hass hass - -"
    "f /var/lib/hass/scenes.yaml 0644 hass hass - -"
  ];

  # Open the port for Home Assistant (only on Tailscale interface)
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 8123 22 ];

  # Only accept SSH connections from tailscale
  services.openssh.openFirewall = false;

  # Allow Home Assistant to access serial devices for Zigbee
  users.users.hass.extraGroups = [ "dialout" "tty" ];
}
