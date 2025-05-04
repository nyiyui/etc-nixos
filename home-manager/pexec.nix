{ pkgs, ... }: {
  home.packages = [
    (pkgs.writeShellScriptBin "pexec" ''
      res="$(wl-paste | exec $@)"
      notify-desktop -t 10000 "$res" "$*"
    '')
  ];
}
