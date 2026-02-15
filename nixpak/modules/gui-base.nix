# based on https://github.com/nixpak/nixpak/blob/4276954ad4f877d79801fd8952af38a3370bcb65/contrib/modules/gui-base.nix
{
  config,
  lib,
  pkgs,
  sloth,
  ...
}:
{
  config = {
    dbus.enable = lib.mkDefault true;
    dbus.policies = {
      "${config.flatpak.appId}" = "own";
      "${config.flatpak.appId}.*" = "own";
      "org.freedesktop.DBus" = "talk";
      "org.gtk.vfs.*" = "talk";
      "org.gtk.vfs" = "talk";
      "ca.desrt.dconf" = "talk";
      "org.freedesktop.portal.*" = "talk";
      "org.freedesktop.StatusNotifierItem" = "talk";
      "org.kde.StatusNotifierWatcher" = "talk";
      "org.a11y.Bus" = "talk";
    };
    gpu.enable = lib.mkDefault true;
    fonts.enable = true;
    locale.enable = true;
    bubblewrap = {
      network = lib.mkDefault false;
      sockets = {
        wayland = true;
        pulse = true;
        pipewire = true;
      };
      bind.rw = [
        [
          sloth.appCacheDir
          sloth.xdgCacheHome
        ]
        (sloth.concat' sloth.xdgCacheHome "/fontconfig")
        (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache")
        (sloth.concat' sloth.xdgCacheHome "/mesa_shader_cache_db")
        (sloth.concat' sloth.xdgCacheHome "/radv_builtin_shaders")

        (sloth.concat' sloth.runtimeDir "/at-spi/bus")
        (sloth.concat' sloth.runtimeDir "/gvfsd")
        (sloth.concat' sloth.runtimeDir "/dconf")
        (sloth.concat' sloth.runtimeDir "/doc")
      ];
      bind.ro = [
        (lib.optionalString config.dbus.enable "/etc/machine-id")
        (sloth.concat' sloth.xdgConfigHome "/gtk-2.0")
        (sloth.concat' sloth.xdgConfigHome "/gtk-3.0")
        (sloth.concat' sloth.xdgConfigHome "/gtk-4.0")
        (sloth.concat' sloth.xdgConfigHome "/fontconfig")
        (sloth.concat' sloth.xdgConfigHome "/dconf")
      ];
      env = {
        # NOTE: `GTK_USE_PORTAL=1` makes GTK route file picking through xdg-desktop-portal.
        GTK_USE_PORTAL = "1";
        XDG_DATA_DIRS = lib.makeSearchPath "share" [
          pkgs.adwaita-icon-theme
          pkgs.shared-mime-info
        ];
        XCURSOR_PATH = lib.concatStringsSep ":" [
          "${pkgs.adwaita-icon-theme}/share/icons"
          "${pkgs.adwaita-icon-theme}/share/pixmaps"
        ];
      };
    };
    timeZone.enable = true;
  };
}
