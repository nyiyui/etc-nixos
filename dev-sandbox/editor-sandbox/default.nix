{ config, lib, ... }:
{
  imports = [
    ./editor.nix
    ./toolchain-sandbox.nix
  ];

  options.assr.editor-sandbox.enable = lib.mkEnableOption "editor sandbox (Helix + LSPs)";
}
