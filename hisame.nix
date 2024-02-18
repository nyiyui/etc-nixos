# TODO: change to systemd user service, that seems to work™
# hisame.nix configures stuff from my Fujitsu Quaderno A4.
{ config, pkgs, ... }: {
  programs.fuse.userAllowOther = true;
  home-manager.extraSpecialArgs.dptmountData = {
   clientId = config.age.secrets."hisame/deviceid.dat".path;
   key = config.age.secrets."hisame/privatekey.dat".path;
  };
  age.secrets."hisame/privatekey.dat" = {
    file = ./secrets/hisame/privatekey.dat.age;
    owner = "nyiyui";
    group = "nyiyui";
    mode = "400";
  };
  age.secrets."hisame/deviceid.dat" = {
    file = ./secrets/hisame/deviceid.dat.age;
    owner = "nyiyui";
    group = "nyiyui";
    mode = "400";
  };

  services.avahi.enable = true;
}
