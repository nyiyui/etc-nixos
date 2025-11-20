{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Allow kiyurica to monitor systemd D-Bus messages without sudo
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          subject.user == "kiyurica") {
        return polkit.Result.YES;
      }
    });
  '';

  # Allow kiyurica user to use D-Bus monitoring (for busctl monitor)
  services.dbus.packages = [
    (pkgs.writeTextFile {
      name = "dbus-monitor-policy";
      destination = "/etc/dbus-1/system.d/allow-kiyurica-monitoring.conf";
      text = ''
        <!DOCTYPE busconfig PUBLIC
         "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN"
         "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
        <busconfig>
          <policy user="kiyurica">
            <allow send_destination="org.freedesktop.DBus"
                   send_interface="org.freedesktop.DBus.Monitoring"/>
          </policy>
        </busconfig>
      '';
    })
  ];
}
