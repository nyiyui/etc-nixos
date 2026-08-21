{ pkgs, ... }:

let
  # Tarmak Stage 1: transitional QWERTY → Colemak layout
  # Changes: E→J, J→N, K→E, N→K (output remapping by physical key position)
  symbolsFile = pkgs.writeText "tarmak1" ''
    xkb_symbols "tarmak1" {
        include "us"

        // Tarmak Stage 1
        key <AD03> { [ j, J ] };  // E position → J
        key <AC07> { [ n, N ] };  // J position → N
        key <AC08> { [ e, E ] };  // K position → E
        key <AB06> { [ k, K ] };  // N position → K
    };
  '';
in
{
  services.xserver.xkb.extraLayouts.tarmak1 = {
    description = "Tarmak Stage 1 (QWERTY to Colemak)";
    languages = [ "eng" ];
    symbolsFile = symbolsFile;
  };

  # (not tested)
  # undo Tarmak changes for YubiKeys only
  services.udev.extraHwdb = ''
    evdev:input:b0003v1050p*
     KEYBOARD_KEY_70008=k
     KEYBOARD_KEY_7000d=e
     KEYBOARD_KEY_7000e=n
     KEYBOARD_KEY_70011=j
  '';
}
