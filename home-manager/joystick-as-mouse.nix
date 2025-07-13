{ pkgs, nixpkgs-unstable, ... }:
let
  pkgs-unstable = import nixpkgs-unstable { system = pkgs.system; };
  pythonEnv = pkgs-unstable.python3.withPackages (
    ps: with ps; [
      evdev
      python-uinput
      black
    ]
  );
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "joystick-as-mouse.sh" ''
      ${pythonEnv}/bin/python3 ${./joystick_as_mouse.py}
    '')
    pkgs.wl-kbptr
  ];
}
