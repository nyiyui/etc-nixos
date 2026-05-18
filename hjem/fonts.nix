{ pkgs, ... }:
{
  packages = with pkgs; [
    jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
