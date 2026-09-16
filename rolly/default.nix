                                                                                    {























                                                                                    lib
                                                                    , makePackageSet
                                    ,

















                                     fetchFromGitHub
}:

let
  src = fetchFromGitHub {
  owner = "Ashwagandhae";
  repo = "rolly";
  rev = "5a6e1150ade61aec343ba0b5f4601e6bb14ce7dd";
  hash = "sha256-zhrLkLOECl0wdrSI3+C+CUERc61jOGTvEnFsKUdQW+o=";
  };

  rustPkgs = makePackageSet {
    packageFun = import ./Cargo.nix;

    workspaceSrc = src;

  };
in
{
  best-game-ik = (rustPkgs.workspace.my-app {}).out;
}
