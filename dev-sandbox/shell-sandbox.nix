{
  config,
  lib,
  pkgs,
  nixwrap,
  ...
}:
{
  options.assr.shell-sandbox.enable = lib.mkEnableOption "sandboxed development environment based on bubblewrap";

  config =
    let
      wrap = nixwrap.packages.${pkgs.stdenv.hostPlatform.system}.wrap;
      shell-sandbox = pkgs.writeShellScriptBin "shell-sandbox" ''
        KIYURICA_IN_SHELL_SANDBOX=yes nix develop --command wrap -e KIYURICA_IN_SHELL_SANDBOX -r "$HOME/.config/fish" "$@" "$SHELL"
      '';
    in
    lib.mkIf config.assr.shell-sandbox.enable {
      users.users.kiyurica.packages = [
        wrap
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
