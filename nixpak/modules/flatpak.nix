# Use like so: imports = [ (import ../modules/flatpak.nix { appId = "com.example.app"; }) ]
{ appId }:
{
  config.flatpak.appId = appId;
  config.bubblewrap.env.FLATPAK_APP_ID = appId;
}
