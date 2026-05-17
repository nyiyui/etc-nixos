{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.assr.desktop.niri.enable && config.assr.desktop.niri.default) {
    kiyurica.greeter.gtkgreet.compositor = [ "/run/current-system/sw/bin/niri --session" ];
  };
}
