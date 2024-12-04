{
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../headless.nix
    ../base.nix
    ../syncthing.nix
    ../autoUpgrade-https.nix
    ../hisame.nix
    ./jks.nix
  ];

  hisame.services.sync = {
    enable = true;
    path = "/home/nyiyui/inaba/hisame";
  };

  networking.hostName = "yagoto";

  sdImage.compressImage = false;
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_CA.UTF-8";

  users.users.root.initialHashedPassword = "$y$j9T$Oy.M1VzXQXFNXhLpsqbi..$lkvdnMD9WTyKc5ek7Dx3XoeyqKGtvEAuVhabHNyyz0D";
  system = {
    stateVersion = "24.05";
  };
  networking = {
    wireless.enable = false;
  };
  environment.systemPackages = with pkgs; [ ];

  fileSystems."/portable0" = {
    label = "portable0";
    fsType = "ext4";
    device = "/dev/disk/by-uuid/e44a6d2d-224c-410f-a4e8-39b34af3966a";
  };

  services.syncthing.settings.folders."inaba".path = lib.mkForce "/portable0/inaba";
  services.syncthing.settings.folders."geofront".path = lib.mkForce "/portable0/GF-01";
  services.syncthing.settings.folders."hisame".path = lib.mkForce "/portable0/hisame";

  systemd.timers.autoupgrade-pull.timerConfig.OnCalendar = lib.mkForce "daily";
  system.autoUpgrade.dates = lib.mkForce "02:30";
}
