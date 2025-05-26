{ pkgs, ... }:
let
  package = (import ./package.nix { inherit pkgs; });
  claude-code = package."@anthropic-ai/claude-code";
in
{
  home.packages = [ "${claude-code}" ];
}
