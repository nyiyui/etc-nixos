{ pkgs, ... }:
{
  services.activitywatch = {
    enable = true;
    package = pkgs.aw-server-rust;
    # there is supposed to be a Firefox watcher (installed via Firefox Sync)
  };
}
