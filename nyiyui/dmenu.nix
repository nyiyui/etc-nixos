{ pkgs, ... }: {
  home.packages = [
    (pkgs.dmenu.overrideAttrs (oldAttrs: rec {
      configFile =
        writeText "config.def.h" (builtins.readFile ./dmenu.config.def.h);
      postPatch = ''
        ${oldAttrs.postPatch}
         cp ${configFile} config.def.h'';
      patches = [
        ./dmenu-alpha-20210605-1a13d04.diff
        # below is workaround for alpha patch (add -lXrender to config.mk)
        ./dmenu-alpha-mk.patch
      ];
    }))
  ];
}
