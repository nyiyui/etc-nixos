{ pkgs, ... }:

let
  # Tarmak Stage 1: transitional QWERTY → Colemak layout
  # Changes: E→J, J→N, K→E, N→K (output remapping by physical key position)
  # ykpersonalize -y -S0605070e090a0b0c08110f0d151718198685878e898a8b8c88918f8d95979899271e1f202122232425269e2b28
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
}
