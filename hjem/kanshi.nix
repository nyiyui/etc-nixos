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
      
      settings = [
        {
          profile.name = "eastyork-dock";
          profile.outputs = [
            { criteria = "Sceptre Tech Inc U27 Unknown"; position = "0,0"; transform = "270"; mode = "3840x2160@30.000Hz"; scale = 2.4; }
            { criteria = "Sony SONY TV  *00 0x01010101"; position = "900,160"; mode = "3840x2160@30.000Hz"; scale = 1.5; }
            { criteria = builtinDisplay; position = "900,1600"; }
          ];
        }
        {
          profile.name = "eastyork-dock2";
          profile.outputs = [
            { criteria = "Sony SONY TV  *00 0x01010101"; position = "0,0"; mode = "3840x2160@30.000Hz"; scale = 1.5; }
            { criteria = builtinDisplay; position = "0,1440"; }
          ];
        }
        {
          profile.name = "eastyork-dock-closed";
          profile.outputs = [
            { criteria = "Sceptre Tech Inc U27 Unknown"; position = "0,0"; transform = "270"; mode = "3840x2160@30.000Hz"; scale = 2.4; }
            { criteria = "Sony SONY TV  *00 0x01010101"; position = "900,160"; mode = "3840x2160@30.000Hz"; scale = 1.5; }
          ];
        }
        {
          profile.name = "eastyork-dock2-closed";
          profile.outputs = [
            { criteria = "Sony SONY TV  *00 0x01010101"; position = "0,0"; mode = "3840x2160@30.000Hz"; scale = 1.5; }
          ];
        }
        {
          profile.name = "clough-pink";
          profile.outputs = [
            { criteria = "Dell Inc. DELL U2417H *"; position = "1920,0"; mode = "1920x1080@60.000Hz"; scale = 1.0; }
            { criteria = builtinDisplay; position = "0,1080"; }
          ];
        }
        {
          profile.name = "builtin-only";
          profile.outputs = [
            { criteria = builtinDisplay; position = "0,0"; }
          ];
        }
        {
          profile.name = "wide-only";
          profile.outputs = [
            { criteria = builtinDisplay; status = "disable"; }
            { criteria = "Samsung Electric Company LC34G55T *"; position = "0,0"; }
          ];
        }
        {
          profile.name = "tv-only";
          profile.outputs = [
            { criteria = builtinDisplay; status = "disable"; }
            { criteria = "Hisense Electric Co., Ltd. HISENSE-TV 0x81010101"; mode = "3840x2150@60.000Hz"; scale = 1.5; }
          ];
        }
      ] ++ (lib.lists.imap0 (i: name: {
        profile.name = "edu.gatech.ece.hive.floor3.${builtins.toString i}";
        profile.outputs = [
          { criteria = name; position = "0,0"; }
          { criteria = builtinDisplay; position = "0,1080"; }
        ];
      }) [
        "Dell Inc. DELL P2419H HX6JPM2"
        "Dell Inc. DELL P2419H HNNGPM2"
        "Dell Inc. DELL P2419H HP5JPM2"
        "Dell Inc. DELL P2419H HS3KPM2"
        "Dell Inc. DELL P2419H HNRGPM2"
      ]);

      mkOutput = out:
        let
          props = lib.attrsets.mapAttrsToList (k: v: if k == "criteria" then "" else "${k} ${builtins.toString v}") out;
        in
        ''output "${out.criteria}" ${lib.concatStringsSep " " (lib.filter (x: x != "") props)}'';

      mkProfile = p: ''
        profile ${p.profile.name} {
          ${lib.concatStringsSep "\n  " (map mkOutput p.profile.outputs)}
        }
      '';

    in
    lib.mkIf config.kiyurica.services.kanshi.enable {
      packages = [ pkgs.kanshi ];
      xdg.config.files."kanshi/config".text = lib.concatStringsSep "\n" (map mkProfile settings);
    };
}