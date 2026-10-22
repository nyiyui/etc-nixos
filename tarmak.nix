{ pkgs, ... }:

let
  # Tarmak Stage 4: transitional QWERTY → Colemak layout
  # ykpersonalize -y -S06050a0e08170b0c1c110f0d1609181986858a8e88978b8c9c918f8d96899899271e1f202122232425269e2b28

  symbolsFile = pkgs.writeText "tarmak4" ''
    xkb_symbols "tarmak4" {
        include "us"

        // Tarmak Stage 4
        key <AD03> { [ f, F ] };               // E position → F
        key <AD05> { [ g, G ] };               // T position → G
        key <AD06> { [ j, J ] };               // Y position → J
        key <AD09> { [ y, Y ] };               // O position → Y
        key <AD10> { [ semicolon, colon ] };   // P position → ;
        key <AC02> { [ r, R ] };               // S position → R
        key <AC03> { [ s, S ] };               // D position → S
        key <AC04> { [ t, T ] };               // F position → T
        key <AC05> { [ d, D ] };               // G position → D
        key <AC07> { [ n, N ] };               // J position → N
        key <AC08> { [ e, E ] };               // K position → E
        key <AC10> { [ o, O ] };               // ; position → O
        key <AD04> { [ p, P ] };               // R position → P
        key <AB06> { [ k, K ] };               // N position → K
    };
  '';
in
{
  services.xserver.xkb.extraLayouts.tarmak4 = {
    description = "Tarmak Stage 4 (QWERTY to Colemak)";
    languages = [ "eng" ];
    symbolsFile = symbolsFile;
  };
  services.xserver.xkb.layout = "tarmak4";
  services.xserver.xkb.options = "compose:caps";
  # niri reads XKB_DEFAULT_* env vars rather than services.xserver.xkb directly
  environment.variables = {
    XKB_DEFAULT_LAYOUT = "tarmak4";
    XKB_DEFAULT_OPTIONS = "compose:caps";
  };
  # apply the xkb layout to the Linux console (TTY) as well
  console.useXkbConfig = true;
}
