{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.assr.gpu-screen-recorder;
in
{
  options.assr.gpu-screen-recorder = {
    enable = lib.mkEnableOption "GPU Screen Recorder";
  };

  config = lib.mkIf cfg.enable {
    programs.gpu-screen-recorder.enable = true;

    environment.systemPackages = with pkgs; [
      gpu-screen-recorder
      gpu-screen-recorder-gtk
    ];
  };
}
