{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.assr.shell-sandbox.enable = lib.mkEnableOption "sandboxed development environment based on bubblewrap";

  config =
    let
      # TODO: nix develop should pass through certain envvars only
      # TODO: wrap should pass through envvars set by nix develop
      shell-sandbox = pkgs.writeShellScriptBin "shell-sandbox" ''
        KIYURICA_IN_SHELL_SANDBOX=yes nix develop --ignore-env --command ${pkgs.nixwrap-wrap}/bin/wrap -e KIYURICA_IN_SHELL_SANDBOX -r "$HOME/.config/fish" "$@" "$SHELL"
      '';
    in
    lib.mkIf config.assr.shell-sandbox.enable {
      users.users.kiyurica.packages = [
        pkgs.nixwrap-wrap
        shell-sandbox
      ];

      kiyurica.home-manager.enable = true;
      home-manager.users.kiyurica.programs.fish.interactiveShellInit = ''
        functions -c fish_prompt _original_fish_prompt
        function fish_prompt
          if test -n "$KIYURICA_IN_SHELL_SANDBOX"
            set_color -o red
            echo -n '[SANDBOX] '
            set_color normal
          end
          _original_fish_prompt
        end
      '';
    };
}
