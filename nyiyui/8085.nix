{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "8085-simulator" ''
      ${pkgs.openjdk}/bin/java -jar ${../8085Compiler.jar}
    '')
  ];
}
