{ config, lib, ... }:
{
  options.kiyurica.sandbox-dev.enable = lib.mkEnableOption "development sandbox (shell + editor)";

  config = lib.mkIf config.kiyurica.sandbox-dev.enable {
    assr.dev-sandbox.enable = true;
  };
}
