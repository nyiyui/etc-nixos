{
  config,
  lib,
  pkgs,
  nixwrap,
  ...
}:
{
  options.kiyurica.sandbox-dev.enable = lib.mkEnableOption "sandboxed development environment based on bubblewrap";

  config =
    let
      wrap = nixwrap.packages.${pkgs.stdenv.hostPlatform.system}.wrap;
      sandbox-dev-command = pkgs.writeShellScriptBin "sandbox-dev-command" ''
        KIYURICA_IN_SANDBOX_DEV=yes nix develop --command wrap -e KIYURICA_IN_SANDBOX_DEV -r "$HOME/.config/fish" "$@" "$SHELL"
      '';
    in
    lib.mkIf config.kiyurica.sandbox-dev.enable {
      users.users.kiyurica.packages = [
        wrap
        sandbox-dev-command
      ];

      kiyurica.home-manager.enable = true;
      home-manager.users.kiyurica.programs.fish.interactiveShellInit = ''
        functions -c fish_prompt _original_fish_prompt
        function fish_prompt
          if test -n "$KIYURICA_IN_SANDBOX_DEV"
            set_color -o red
            echo -n '[SANDBOX] '
            set_color normal
          end
          _original_fish_prompt
        end
      '';
    };
}
