{ config, lib, ... }:
{
  imports = [
    ./shell-sandbox.nix
    ./editor-sandbox
  ];

  options.assr.dev-sandbox.enable = lib.mkEnableOption "complete development sandbox (shell + editor)";

  config = lib.mkIf config.assr.dev-sandbox.enable {
    assr.shell-sandbox.enable = true;
    assr.editor-sandbox.enable = true;
  };
}
