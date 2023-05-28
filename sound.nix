{ pkgs, ... }:
{
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    config.jack = {
      context.properties.default.clock.allowed-rates = [ 48000 ];
    };
  };

  environment.systemPackages = with pkgs; [ qjackctl ];
}
