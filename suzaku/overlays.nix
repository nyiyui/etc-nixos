{ nixpkgs-unstable, ... }:
let
  swayOverlay =
    final: prev:
    let
      unstable = import nixpkgs-unstable { system = prev.system; };
    in
    {
      sway = unstable.sway;
    };
in
{
  nixpkgs.overlays = [ swayOverlay ];
  home-manager.users.kiyurica = {
    nixpkgs.overlays = [ swayOverlay ];
  };
}
