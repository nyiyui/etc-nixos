{ pkgs, ... }:
{
  programs.adb.enable = true;
  users.users.kiyurica.extraGroups = [ "adbusers" ];
}
