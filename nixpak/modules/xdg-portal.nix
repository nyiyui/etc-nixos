{ sloth, ... }:
{
  # NOTE: FLATPAK_APP_ID may be needed to nudge GTK to treat this as a sandboxed app use the XDG doc portal.
  config.bubblewrap.env.GTK_USE_PORTAL = "1";
  config.bubblewrap.bind.rw = [
    (sloth.concat' sloth.runtimeDir "/doc")
  ];
}
