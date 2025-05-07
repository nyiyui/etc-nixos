{ pkgs, ... }:
{
  home.packages = with pkgs; [
    jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-emoji
  ];
}
