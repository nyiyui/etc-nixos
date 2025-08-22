{ pkgs, ... }:
let
  package = (import ./package.nix { inherit pkgs; });
  gemini-cli = package."@google/gemini-cli";
in
{
  home.packages = [ "${gemini-cli}" ];
}
