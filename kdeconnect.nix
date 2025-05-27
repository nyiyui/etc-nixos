{ config, lib, ... }: {
  options.kiyurica.kdeconnect.enable = lib.mkEnableOption "smartphone renkei service";

  config = lib.mkIf config.kiyurica.kdeconnect.enable {
    programs.kdeconnect.enable = true;
  };
}
