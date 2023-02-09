{ config, lib, pkgs, ... }:
{ 
  programs.tmux = {
    enable = true;
    historyLimit = 10000;
    mouse = true;
    prefix = "C-a";
    shell = "${pkgs.fish}/bin/fish";
    terminal = "screen-256color";
    extraConfig = ''
      set-option -g detach-on-destroy off # https://superuser.com/a/1717231
    '';
  };
}
