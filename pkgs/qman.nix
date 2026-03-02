{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  ncurses,
  python3Packages,
  zlib,
  bzip2,
  xz,
}:
stdenv.mkDerivation rec {
  pname = "qman";
  version = "1.5.1";

  src = fetchurl {
    url = "https://github.com/plp13/qman/archive/refs/tags/v${version}.tar.gz";
    hash = "sha256-5VCVhSPQ/vkP0BI6YajxAJntDJc14G2BUmYtiWW1oOE=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3Packages.cogapp
  ];

  buildInputs = [
    ncurses
    zlib
    bzip2
    xz
  ];

  meta = with lib; {
    description = "A more modern manual page viewer for our terminals";
    homepage = "https://github.com/plp13/qman";
    license = licenses.bsd2;
    platforms = platforms.linux;
    mainProgram = "qman";
  };
}
