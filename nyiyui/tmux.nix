{ config, lib, pkgs, ... }: {
  programs.tmux = {
    enable = true;
    historyLimit = 10000;
    #mouse = true;
    prefix = "C-a";
    shell = "${pkgs.fish}/bin/fish";
    terminal = "screen-256color";
    extraConfig = ''
      set -g mouse
      set-option -g detach-on-destroy off # https://superuser.com/a/1717231
    '';
    plugins = with pkgs.tmuxPlugins; [{
      # https://superuser.com/questions/1522901/tmux-disable-mouse-when-entering-vim/1523181#1523181
      plugin = better-mouse-mode;
      extraConfig = ''
        set -g @emulate-scroll-for-no-mouse-alternate-buffer "on"
      '';
    }];
  };
}
