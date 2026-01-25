{ pkgs, ... }:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    wireplumber.enable = true;
    pulse.enable = true; # needed by Firefox
  };

  home-manager.users.kiyurica = {
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
