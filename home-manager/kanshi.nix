{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.kiyurica.services.kanshi.enable =
    lib.mkEnableOption "dynamic display configuration for Wayland compositors supporting wlr-output-management protocol";
  options.kiyurica.services.kanshi.builtinDisplay = lib.mkOption {
    type = lib.types.str;
    description = "name of the builtin display";
    example = "Samsung Display Corp. 0x4152 Unknown";
  };

  config =
    let
      builtinDisplay = config.kiyurica.services.kanshi.builtinDisplay;
    in
    lib.mkIf config.kiyurica.services.kanshi.enable {
      services.kanshi = {
        enable = true;
        settings = [
          {
            output.criteria = "Sceptre Tech Inc U27 Unknown";
            output.transform = "270";
            output.mode = "3840x2160@30.000Hz";
            output.scale = 2.4;
            output.alias = "Sceptre";
          }
          {
            output.criteria = "Sony SONY TV  *00 0x01010101";
            output.mode = "3840x2160@30.000Hz";
            output.scale = 1.5;
            output.alias = "Sony";
          }
          {
            output.criteria = "Dell Inc. DELL U2417H XVNNT87AAH3L";
            output.mode = "1920x1080@60.000Hz";
            output.scale = 1.0;
            output.alias = "CloughPinkR";
          }
          {
            output.criteria = "Dell Inc. DELL U2417H XVNNT87A025W";
            output.mode = "1920x1080@60.000Hz";
            output.scale = 1.0;
            output.alias = "CloughPinkL";
          }
          {
            profile.name = "eastyork-dock";
            profile.outputs = [
              {
                criteria = "$Sceptre";
                position = "0,0";
              }
              {
                criteria = "$Sony";
                position = "900,160";
              }
              {
                criteria = "${builtinDisplay}";
                position = "900,1600";
              }
            ];
          }
          {
            profile.name = "eastyork-dock-closed";
            profile.outputs = [
              {
                criteria = "$Sceptre";
                position = "0,0";
              }
              {
                criteria = "$Sony";
                position = "900,160";
              }
            ];
          }
          {
            profile.name = "clough-pink";
            profile.outputs = [
              {
                criteria = "$CloughPinkL";
                position = "0,0";
              }
              {
                criteria = "$CloughPinkR";
                position = "1920,0";
              }
              {
                criteria = "${builtinDisplay}";
                position = "0,1080";
              }
            ];
          }
          {
            profile.name = "builtin-only";
            profile.outputs = [
              {
                criteria = "${builtinDisplay}";
                position = "0,0";
              }
            ];
          }
        ] ++ lib.lists.flatten (lib.lists.imap0 (i: name: {
          profile.name = "edu.gatech.ece.hive.floor3.${builtins.toString i}";
          profile.outputs = [
            { criteria = name; position = "0,0"; }
            { criteria = builtinDisplay; position = "0,1080"; }
          ];
        }) ["Dell Inc. DELL P2419H HX6JPM2"]);
      };
    };
}
