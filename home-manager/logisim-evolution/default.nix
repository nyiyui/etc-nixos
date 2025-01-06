{ pkgs, ... }: {
  home.packages = [
    (pkgs.writeShellScriptBin "logisim-evolution" ''
      export _JAVA_AWT_WM_NONREPARENTING=1
      ${pkgs.openjdk}/bin/java -jar ${./logisim-evolution-3.8.0-all.jar}
    '')
  ];
}

