{ ... }:
{
  nix = {
    settings = {
      substituters = [
        "http://cirno.msb.q.nyiyui.ca:5000/"
      ];
      trusted-public-keys = [
        "cirno.nyiyui.ca:PqEwVnkqqR4o+bs+fV4bWPU6Qnel0ffKqFAMhBohxMM="
      ];
    };
  };
}
