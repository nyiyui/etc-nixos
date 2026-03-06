{ config, lib, ... }:
{
  imports = [
    ./editor.nix
    ./toolchain-sandbox.nix
  ];

  options.assr.dev-sandbox.enable = lib.mkEnableOption "dev sandbox";
}
