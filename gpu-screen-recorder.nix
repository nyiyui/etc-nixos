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

      # Synthesize a .desktop file so GNOME's portal trusts the binary
      # (according to Gemini, untested)
      (pkgs.makeDesktopItem {
        name = "gpu-screen-recorder";
        desktopName = "GPU Screen Recorder CLI";
        exec = "gpu-screen-recorder";
        icon = "video-display";
        terminal = true;
        type = "Application";
        categories = [
          "AudioVideo"
          "Recorder"
        ];
      })
    ];
  };
}
