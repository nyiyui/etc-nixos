{
  inputs = {
    flake-utils.url = github:numtide/flake-utils;
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem (system: let
    pkgs = nixpkgs.legacyPackages.${system};
  in rec {
    packages.default = pkgs.stdenv.mkDerivation {
      name = "udp2raw";
      src = pkgs.fetchFromGitHub {
        owner = "wangyu-";
        repo = "udp2raw";
        rev = "cc6ea766c495cf4c69d1c7485728ba022b0f19de";
        sha256 = "TkTOfF1RfHJzt80q0mN4Fek3XSFY/8jdeAVtyluZBt8=";
      };
      buildPhase = ''
        make dynamic
      '';
      postFixup = ''
        wrapProgram $out/bin/udp2raw \
          --set PATH ${pkgs.lib.makeBinPath [ pkgs.iptables ]}
      '';
      installPhase = ''
        mkdir -p $out/bin
        cp udp2raw_dynamic $out/bin/udp2raw
      '';
      nativeBuildInputs = with pkgs; [
        pkg-config
        pkgs.makeWrapper
      ];
    };
  });
}
