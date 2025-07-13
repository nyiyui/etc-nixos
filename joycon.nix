# joycon support
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kiyurica.joycon.enable = lib.mkEnableOption "Nintendo Joycon support";

  config = lib.mkIf config.kiyurica.joycon.enable {
    services.joycond.enable = true;
  };
}
