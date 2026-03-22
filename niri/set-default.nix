{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf (config.kiyurica.desktop.niri.enable && config.kiyurica.desktop.niri.default) {
    kiyurica.greeter.gtkgreet.compositor = [ "/run/current-system/sw/bin/niri --session" ];
  };
}
