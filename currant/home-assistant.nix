{ pkgs, ... }:
{
  services.home-assistant = {
    enable = true;
    customComponents = [
      (pkgs.callPackage ../southern-company-hacs.nix { })
    ];
    extraComponents = [
      "zha"
      "default_config"
      "met"
      "bluetooth"
      "switchbot"
      "matter"
    ];
    config = {
      # Configures Home Assistant and its Zigbee integration via the UI
      default_config = { };
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
      logger = {
        default = "info";
        logs = {
          "homeassistant.components.bluetooth" = "info";
        };
      };
    };
  };

  # Matter server, so the Matter integration can talk to Matter devices
  # (e.g. a SwitchBot Hub 2 bridging its sensors) entirely locally, no
  # cloud round-trip. Home Assistant's Matter integration connects to it
  # over the local WebSocket API (ws://localhost:5580/ws).
  services.matter-server = {
    enable = true;
    # Not exposed outside localhost: only the co-located Home Assistant
    # instance needs to reach it.
    openFirewall = false;
  };

  # Ensure writable files exist for the UI to manage
  systemd.tmpfiles.rules = [
    "f /var/lib/hass/automations.yaml 0644 hass hass - -"
    "f /var/lib/hass/scripts.yaml 0644 hass hass - -"
    "f /var/lib/hass/scenes.yaml 0644 hass hass - -"
  ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    8123
  ];

  # Allow Home Assistant to access serial devices and bluetooth
  users.users.hass.extraGroups = [
    "dialout"
    "tty"
    "bluetooth"
  ];
}
