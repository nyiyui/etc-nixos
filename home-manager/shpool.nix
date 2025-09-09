{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = [ pkgs.shpool ];
  
  programs.fish.shellInit = lib.mkAfter ''
    # Auto-attach to shpool session
    if status is-interactive
      and not set -q SHPOOL_SESSION_NAME
      shpool attach $(shuf -n 1 ${./shpool-names.txt}) || shpool daemon
      # TODO: select a non-preexsiting name
    end
  '';
}
