{
  stdenv,
  fetchFromGitHub,
  fetchFromGitLab,
  cmake,
  pkg-config,
  pipewire,
  libpulseaudio,
}:
let
  rohrkabel-src = fetchFromGitHub {
    owner = "Soundux";
    repo = "rohrkabel";
    rev = "8ad8d409ab6df5ef8db403667e0a9f53bef39656";
    hash = "sha256-wWJMJs7EKD+7/IR+rJ24e4fI2GS0hQdoTYck+qdNvwY=";
  };

  tiny-process-src = fetchFromGitLab {
    owner = "eidheim";
    repo = "tiny-process-library";
    rev = "8bbb5a211c5c9df8ee69301da9d22fb977b27dc1";
    hash = "sha256-EdaPXKHbAMR2M2FwPnDP+KeuYbGfGE2j5QXB+CyyjnM=";
  };

in
stdenv.mkDerivation rec {
  pname = "gpu-screen-recorder-all-audio";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "Curve";
    repo = "gpu-screen-recorder-all-audio";
    rev = "92dfc86a72e807a7911acb06b9666fa72590da6c";
    hash = "sha256-MSilGW1511GOvCU3GbSREge/CFKDy4QpgoB0yzEfeQ8=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    pipewire
    libpulseaudio
  ];

  preConfigure = ''
        # Create a flat CMakeLists.txt to avoid CPM/FetchContent
        cat > CMakeLists.txt <<EOF
    cmake_minimum_required(VERSION 3.10)
    project(gpu-screen-recorder-all-audio LANGUAGES CXX VERSION 1.0)

    set(CMAKE_CXX_STANDARD 17)

    find_package(PkgConfig REQUIRED)
    pkg_check_modules(PIPEWIRE REQUIRED libpipewire-0.3)
    pkg_check_modules(LIBSPA REQUIRED libspa-0.2)

    # rohrkabel (old version, no extra deps)
    file(GLOB rohrkabel_src "${rohrkabel-src}/src/*.cpp")
    add_library(rohrkabel STATIC \''${rohrkabel_src})
    target_include_directories(rohrkabel PUBLIC ${rohrkabel-src}/include)
    target_include_directories(rohrkabel PRIVATE ${rohrkabel-src}/include/rohrkabel)
    target_include_directories(rohrkabel PRIVATE \''${PIPEWIRE_INCLUDE_DIRS} \''${LIBSPA_INCLUDE_DIRS})
    target_link_libraries(rohrkabel PRIVATE \''${PIPEWIRE_LIBRARIES} pthread)

    # tiny-process-library
    add_library(tiny-process-library STATIC ${tiny-process-src}/process.cpp ${tiny-process-src}/process_unix.cpp)
    target_include_directories(tiny-process-library PUBLIC ${tiny-process-src})

    # main app
    file(GLOB app_src "src/*.cpp")
    add_executable(\''${PROJECT_NAME} \''${app_src})
    target_link_libraries(\''${PROJECT_NAME} PRIVATE rohrkabel tiny-process-library)

    install(TARGETS \''${PROJECT_NAME} DESTINATION bin)
    EOF
  '';

  postInstall = ''
    install -D gpu-screen-recorder-all-audio $out/bin/gpu-screen-recorder-all-audio
  '';
}
