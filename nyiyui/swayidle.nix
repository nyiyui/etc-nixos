{ config,pkgs,lib, ... }: let cfg=config.nyiyui.swayidle; in {
  options.nyiyui.swayidle = with lib;with types; {
    enable = mkOption {
      type = bool;
      description = "Whether to enable swayidle (lock)";
      default = true;
    };
  };
  config = lib.mkIf cfg.enable {
  services.swayidle = {
    enable = true;
    events = [{
      event = "before-sleep";
      command = "${pkgs.swaylock}/bin/swaylock";
    }];
    timeouts = [{
      timeout = 600;
      command = "${pkgs.swaylock}/bin/swaylock";
    }];
  };
};
}
