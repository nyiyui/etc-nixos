{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./home-manager.nix ];

  options.kiyurica.programs.gemini-cli.enable = lib.mkEnableOption "Gemini CLI";

  config = lib.mkIf config.kiyurica.programs.gemini-cli.enable {
    home-manager.users.kiyurica = {
      imports = [ ./home-manager/gemini-cli ];
    };
  };
}
