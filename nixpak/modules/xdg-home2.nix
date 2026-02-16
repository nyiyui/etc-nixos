# xdg-home.nix but should work in more scenarios
# - respects env vars for XDG_*_HOME but still sandboxes them
# - uses ~/.var/app/*/** for storage
# Eventually replace xdg-home.nix with this file.
{ config, sloth, ... }:
let
  inherit (sloth) concat' mkdir appDir;
in
{
  config.bubblewrap = {
    bind.rw = [
      [
        sloth.xdgCacheHome
        (mkdir sloth.appCacheDir)
      ]
      [
        sloth.xdgConfigHome
        (mkdir sloth.appConfigDir)
      ]
      [
        sloth.xdgDataHome
        (mkdir (concat' appDir ".local/share"))
      ]
      [
        sloth.xdgStateHome
        (mkdir (concat' appDir ".local/state"))
      ]
    ];
  };
}
