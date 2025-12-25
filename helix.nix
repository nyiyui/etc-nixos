{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kiyurica.lsps = lib.mkOption {
    type =
      with lib;
      with types;
      listOf (submodule {
        options.package = mkOption { type = package; };
        options.exec-name = mkOption { type = str; };
      });
    description = "Paths to run and the package of LSP servers. These will be wrapped to only run when the dev sandbox is detected via an env var.";
    default = [ ];
  };
  config =
    let
      wrapLsp =
        { package, exec-name }:
        pkgs.writeShellScriptBin "${package.name}-wrapped" ''
          if [[ -z "$KIYURICA_IN_SANDBOX_DEV" ]]; then
            echo '$0 should be run in the sandbox. Set $KIYURICA_IN_SANDBOX_DEV to a nonempty value to bypass.'
            exit 39
          fi

          exec ${package.outPath}/bin/${exec-name}
        '';
    in
    {
      users.users.kiyurica.packages = with pkgs; [ helix ] ++ builtins.map wrapLsp config.kiyurica.lsps;
      environment.variables.editor = lib.mkOverride 900 "hx";
    };
}
