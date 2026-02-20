{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.assr.programs.unity.enable = lib.mkEnableOption "Unity 3D";

  config = lib.mkIf config.assr.program.unity.enable {
    environment.systemPackages = [ pkgs.unityhub ];
  };
}
