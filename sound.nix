{ pkgs, lib, config, ... }:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    wireplumber.enable = true;
    pulse.enable = true; # needed by Firefox
  };

  home-manager.users.kiyurica = lib.mkIf config.kiyurica.home-manager.enable {
    imports = [
      (
        { pkgs, ... }:
        {
          home.packages = [ pkgs.pwvucontrol ];
        }
      )
    ];
  };
}
