{ config, sloth, ... }: let inherit (sloth) concat' mkdir homeDir;
  appDir = concat' homeDir "/.var/app/${config.flatpak.appId}";
  in {
    config.bubblewrap = {
      env = {
        XDG_CONFIG_HOME = mkdir (concat' appDir "/config");
        XDG_CACHE_HOME = mkdir (concat' appDir "/cache");
        XDG_DATA_HOME = mkdir (concat' appDir "/.local/share");
        XDG_STATE_HOME = mkdir (concat' appDir "/.local/state");
        };
      bind.rw = [ appDir ];
    };
}
