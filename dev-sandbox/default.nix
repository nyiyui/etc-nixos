{ config, lib, ... }:
{
  imports = [ ./editor.nix ];

  options.assr.dev-sandbox.enable = lib.mkEnableOption "dev sandbox";
}
