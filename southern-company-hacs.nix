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
    version = "0.6.5";
    pyproject = true;

    src = fetchPypi {
      inherit version;
      pname = "southern_company_api";
      hash = "sha256-vOcU2Pbi9mdiggFT/QIlNeX0prsJUg65phOnTKOwJBU=";
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
  version = "1.0.0";

  src = fetchFromGitHub {
    inherit owner;
    repo = "southern-company-hacs";
    tag = version;
    hash = "sha256-xh7I+5nu/pg1IfTPe/dj+zCDmPnhmpiE5qY4vgiP+0U=";
  };

  propagatedBuildInputs = [ southern-company-api ];

  meta = {
    description = "Southern Company energy integration for Home Assistant";
    homepage = "https://github.com/Southern-Company-HA/southern-company-hacs";
    license = lib.licenses.mit;
  };
}
