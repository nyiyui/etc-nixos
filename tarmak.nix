{ pkgs, ... }:

let
  # Tarmak Stage 2: transitional QWERTY → Colemak layout
  # Changes: E→F, F→T, T→G, G→J, J→N, K→E, N→K (output remapping by physical key position)
  # ykpersonalize -y -S0605070e08170b0c0a110f0d150918198685878e88978b8c8a918f8d95899899271e1f202122232425269e2b28
  symbolsFile = pkgs.writeText "tarmak2" ''
    xkb_symbols "tarmak2" {
        include "us"

        // Tarmak Stage 2
        key <AD03> { [ f, F ] };  // E position → F
        key <AD05> { [ g, G ] };  // T position → G
        key <AC04> { [ t, T ] };  // F position → T
        key <AC05> { [ j, J ] };  // G position → J
        key <AC07> { [ n, N ] };  // J position → N
        key <AC08> { [ e, E ] };  // K position → E
        key <AB06> { [ k, K ] };  // N position → K
    };
  '';
in
{
  services.xserver.xkb.extraLayouts.tarmak2 = {
    description = "Tarmak Stage 2 (QWERTY to Colemak)";
    languages = [ "eng" ];
    symbolsFile = symbolsFile;
  };
  services.xserver.xkb.layout = "tarmak2";
  services.xserver.xkb.options = "compose:caps";
  # niri reads XKB_DEFAULT_* env vars rather than services.xserver.xkb directly
  environment.variables = {
    XKB_DEFAULT_LAYOUT = "tarmak2";
    XKB_DEFAULT_OPTIONS = "compose:caps";
  };
  # apply the xkb layout to the Linux console (TTY) as well
  console.useXkbConfig = true;
}
