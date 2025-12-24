{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kiyurica.lsps = lib.mkOption {
    type = with lib; with types; listOf package;
    description = "All LSP packages. These will be wrapped to only run when the dev sandbox is detected via an env var.";
    default = [ ];
  };
  config =
    let
      wrapLsp =
        lsp:
        pkgs.writeShellScriptBin "${lsp.name}-wrapped" ''
          if [[ -z "$KIYURICA_IN_SANDBOX_DEV" ]]; then
            echo '${lsp.name} should be run in the sandbox. Set $KIYURICA_IN_SANDBOX_DEV to a nonempty value to bypass.'
            exit 39
          fi

          exec ${lsp}/bin/*
        '';
    in
    {
      users.users.kiyurica.packages = with pkgs; [ helix ] ++ builtins.map wrapLsp config.kiyurica.lsps;
      environment.variables.editor = lib.mkOverride 900 "hx";
    };
}
