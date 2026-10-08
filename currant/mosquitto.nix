{ ... }:
{
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        users.homeassistant = {
          hashedPasswordFile = ./mosquitto-homeassistant-hash.txt;
          acl = [ "readwrite #" ];
        };
      }
    ];
  };

  # LAN access for MQTT clients (e.g. 192.168.2.118)
  networking.firewall.interfaces.end0.allowedTCPPorts = [ 1883 ];
}
