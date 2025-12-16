{
  config,
  lib,
  pkgs,
  nixwrap,
  ...
}:
{
  options.kiyurica.sandbox-dev.enable = lib.mkEnableOption "sandboxed development environment based on bubblewrap";

  config = lib.mkIf config.kiyurica.sandbox-dev.enable {
    users.users.kiyurica.packages = [ nixwrap.packages.${pkgs.stdenv.hostPlatform.system}.wrap ];
  };
}
