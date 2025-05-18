{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./home-manager.nix ];

  options.kiyurica.programs.claude-code.enable = lib.mkEnableOption "Claude Code";

  config = lib.mkIf config.kiyurica.desktop.sway.enable {
    home-manager.users.kiyurica = {
      imports = [
        ./home-manager/claude-code
      ];
    };
  };
}
