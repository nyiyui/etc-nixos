{ pkgs, ... }:

let
  # Tarmak Stage 3: transitional QWERTY → Colemak layout
  # Changes: E→F, F→T, T→G, G→D, D→S, S→R, R→J, J→N, K→E, N→K (output remapping by physical key position)
  # ykpersonalize -y -S06050a0e08170b0c15110f0d1609181986858a8e88978b8c95918f8d96899899271e1f202122232425269e2b28
  symbolsFile = pkgs.writeText "tarmak3" ''
    xkb_symbols "tarmak3" {
        include "us"

        // Tarmak Stage 3
        key <AD03> { [ f, F ] };  // E position → F
        key <AD05> { [ g, G ] };  // T position → G
        key <AC04> { [ t, T ] };  // F position → T
        key <AC05> { [ d, D ] };  // G position → D
        key <AC03> { [ s, S ] };  // D position → S
        key <AC02> { [ r, R ] };  // S position → R
        key <AD04> { [ j, J ] };  // R position → J
        key <AC07> { [ n, N ] };  // J position → N
        key <AC08> { [ e, E ] };  // K position → E
        key <AB06> { [ k, K ] };  // N position → K
    };
  '';
in
{
  services.xserver.xkb.extraLayouts.tarmak3 = {
    description = "Tarmak Stage 3 (QWERTY to Colemak)";
    languages = [ "eng" ];
    symbolsFile = symbolsFile;
  };
  services.xserver.xkb.layout = "tarmak3";
  services.xserver.xkb.options = "compose:caps";
  # niri reads XKB_DEFAULT_* env vars rather than services.xserver.xkb directly
  environment.variables = {
    XKB_DEFAULT_LAYOUT = "tarmak3";
    XKB_DEFAULT_OPTIONS = "compose:caps";
  };
  # apply the xkb layout to the Linux console (TTY) as well
  console.useXkbConfig = true;
}
