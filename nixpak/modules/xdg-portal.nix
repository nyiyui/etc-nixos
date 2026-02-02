{ sloth, ... }:
{
  # NOTE: `GTK_USE_PORTAL=1` makes GTK route file picking through xdg-desktop-portal.
  config.bubblewrap.env.GTK_USE_PORTAL = "1";
  config.bubblewrap.bind.rw = [
    (sloth.concat' sloth.runtimeDir "/doc")
  ];
}
