{
  config,
  lib,
  pkgs,
  nixwrap,
  ...
}:
{
  options.assr.shell-sandbox = {
    enable = lib.mkEnableOption "sandboxed development environment based on bubblewrap";
    ai-tools.enable = lib.mkEnableOption "sandboxed AI agent tools (github-copilot-cli, gemini-cli)";
  };

  config =
    let
      wrap = nixwrap.packages.${pkgs.stdenv.hostPlatform.system}.wrap;
      shell-sandbox = pkgs.writeShellScriptBin "shell-sandbox" ''
        KIYURICA_IN_SHELL_SANDBOX=yes nix develop --command wrap -e KIYURICA_IN_SHELL_SANDBOX -r "$HOME/.config/fish" "$@" "$SHELL"
      '';
      sandboxed-github-copilot-cli = pkgs.writeShellScriptBin "github-copilot-cli" ''
        exec ${wrap}/bin/wrap -n \
          -r "$HOME/.config/github-copilot" \
          -r "$HOME/.config/.copilot" \
          -r /etc/passwd \
          -- ${pkgs.github-copilot-cli}/bin/github-copilot-cli "$@"
      '';
      sandboxed-gemini-cli = pkgs.writeShellScriptBin "gemini" ''
        exec ${wrap}/bin/wrap -n \
          -r "$HOME/.gemini" \
          -- ${pkgs.gemini-cli}/bin/gemini "$@"
      '';
    in
    lib.mkMerge [
      (lib.mkIf config.assr.shell-sandbox.enable {
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
      })
      (lib.mkIf config.assr.shell-sandbox.ai-tools.enable {
        users.users.kiyurica.packages = [
          sandboxed-github-copilot-cli
          sandboxed-gemini-cli
        ];
      })
    ];
}
