{ pkgs, ... }:
{
  home.packages = with pkgs; [ rclone restic ];
}
