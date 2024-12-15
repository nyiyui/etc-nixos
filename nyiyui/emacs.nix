{ pkgs, ... }:
{
  services.emacs.enable = true;

  programs.emacs = {
    enable = true;
    package = pkgs.emacs;
    extraPackages = epkgs: [ epkgs.mozc epkgs.agda2-mode ];
    extraConfig = ''
      (setq standard-indent 2)
    '';
  };
}
