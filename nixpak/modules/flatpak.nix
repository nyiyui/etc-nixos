# Use like so: imports = [ (import ../modules/flatpak.nix { appId = "com.example.app"; }) ]
{ appId }:
{
  # FLATPAK_APP_ID is only mentioned in Flatseal's docs, but FLATPAK_ID is mentioned in Flatpak source code:
  # https://github.com/flatpak/flatpak/blob/c27af8a9d90af5573b74f832a079a498caf5d1d1/doc/flatpak-run.xml#L165
  config.flatpak.appId = appId;
  config.bubblewrap.env.FLATPAK_ID = appId;
  config.bubblewrap.env.FLATPAK_APP_ID = appId; # TODO: leave it bc why not
  config.dbus.policies."org.freedesktop.impl.portal.*" = "talk";
}
