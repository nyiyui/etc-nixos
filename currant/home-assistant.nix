{ pkgs, ... }:
{
  services.home-assistant = {
    enable = true;
    customComponents = [
      (pkgs.callPackage ../southern-company-hacs.nix { })
      pkgs.home-assistant-custom-components.adaptive_lighting
    ];
    extraComponents = [
      "zha"
      "default_config"
      "met"
      "waqi"
      "bluetooth"
      "switchbot"
      "hue"
      "wake_on_lan"
    ];
    config = {
      # Configures Home Assistant and its Zigbee integration via the UI
      default_config = { };
      # Adaptive Lighting is configured entirely via the UI (Settings ->
      # Devices and Services -> Adaptive Lighting), but the integration
      # still requires this stub entry to be present in YAML.
      adaptive_lighting = { };
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
      switch = [
        {
          platform = "wake_on_lan";
          name = "Minamo";
          mac = "00:D8:61:C9:B6:F0";
          host = "minamo";
        }
      ];
      logger = {
        default = "info";
        logs = {
          "homeassistant.components.bluetooth" = "info";
        };
      };
    };
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
  networking.firewall.interfaces.end0.allowedTCPPorts = [
    8123
  ];

  # Allow Home Assistant to access serial devices and bluetooth
  users.users.hass.extraGroups = [
    "dialout"
    "tty"
    "bluetooth"
  ];
}
