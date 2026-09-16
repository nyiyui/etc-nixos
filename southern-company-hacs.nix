{
  lib,
  buildHomeAssistantComponent,
  fetchFromGitHub,
  fetchPypi,
  python314Packages,
}:

let
  southern-company-api = python314Packages.buildPythonPackage rec {
    pname = "southern-company-api";
    version = "0.7.1";
    pyproject = true;

    src = fetchPypi {
      inherit version;
      pname = "southern_company_api";
      hash = "sha256-Bfe2xpP4AFsBTnk1TsCBciFf7uZPKNoSU0r74b5QWHU=";
    };

    build-system = [ python314Packages.poetry-core ];

    dependencies = with python314Packages; [
      pyjwt
      aiohttp
    ];
  };
in
buildHomeAssistantComponent rec {
  owner = "Southern-Company-HA";
  domain = "southern_company";
  # Tracking main instead of the 1.0.0 tag: main has fixes not yet released,
  # e.g. the Georgia Power auth chain/reauth fix (#122).
  version = "unstable-2026-09-10";

  src = fetchFromGitHub {
    inherit owner;
    repo = "southern-company-hacs";
    rev = "2da7f8dffe77ee37d9046b66a74f9c2ac077df26";
    hash = "sha256-CiHt+A7RvAw5w89VrfZtLC/fArgfvjMAtRfzb+bezBI=";
  };

  propagatedBuildInputs = [ southern-company-api ];

  meta = {
    description = "Southern Company energy integration for Home Assistant";
    homepage = "https://github.com/Southern-Company-HA/southern-company-hacs";
    license = lib.licenses.mit;
  };
}
