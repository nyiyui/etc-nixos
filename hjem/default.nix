{
  config,
  lib,
  pkgs,
  hjem-rum,
  specialArgs,
  ...
}:

{
  options.kiyurica.hjem.enable = lib.mkEnableOption "hjem configuration";

  config = lib.mkIf config.kiyurica.hjem.enable {
    hjem = {
      specialArgs = specialArgs;
      extraModules = [
        hjem-rum.hjemModules.default
      ];
      users.kiyurica = {
        enable = true;
        directory = "/home/kiyurica";
        imports = [ ./common.nix ];
      };
      clobberByDefault = true;
    };
  };
}
