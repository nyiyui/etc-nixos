{ nixpkgs-unstable, ... }:
let
  swayOverlay =
    final: prev:
    let
      unstable = import nixpkgs-unstable { system = prev.stdenv.hostPlatform.system; };
    in
    {
      sway = unstable.sway;
    };
in
{
  nixpkgs.overlays = [ swayOverlay ];
}
