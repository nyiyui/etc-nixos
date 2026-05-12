{ lib, ... }:
let
  lsmod = builtins.readFile ./lsmod.txt;
  lines = lib.splitString "\n" lsmod;
  # Filter out the header "Module", empty lines, and lines starting with space
  modules = lib.filter (x: x != "" && x != "Module" && !(lib.hasPrefix " " x)) lines;
  # Extract only the module name (first column)
  moduleNames = map (line: builtins.head (lib.filter (x: x != "") (lib.splitString " " line))) modules;
in
{
  boot.kernelModules = moduleNames;
  security.lockKernelModules = lib.mkDefault true;
}
