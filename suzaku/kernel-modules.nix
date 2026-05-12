# Kernel module allowlist
#
# To find what modules udev tried to load:
# run0 udevadm control --log-priority=debug
# run0 journalctl -u systemd-udevd -f | grep -iE 'modprobe|module|kmod'
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
