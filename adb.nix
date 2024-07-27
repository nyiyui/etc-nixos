{ pkgs, ... }: {
  programs.adb.enable = true;
  users.users.nyiyui.extraGroups = [ "adbusers" ];
}
