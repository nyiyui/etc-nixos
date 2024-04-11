{ config, pkgs, lib, specialArgs, ... }:
{
  programs.niri.config = builtins.readFile ./config.kdl;
}
