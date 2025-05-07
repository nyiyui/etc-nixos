{ pkgs, ... }:
{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  home-manager.users.kiyurica = {
    imports = [
      (
        { pkgs, ... }:
        {
          home.packages = [ pkgs.helvum ];
        }
      )
    ];
  };
}
