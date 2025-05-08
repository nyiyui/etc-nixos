{
  config,
  lib,
  pkgs,
  modulesPath,
  nixos-hardware,
  disko,
  impermanence,
  ...
}:
{
  imports = [
    nixos-hardware.nixosModules.raspberry-pi-3
    disko.nixosModules.disko
    impermanence.nixosModules.impermanence
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
    ../headless.nix
    ../base.nix
    ./disko-config.nix
    ./impermanence.nix
    #../autoUpgrade-git.nix # enable after initial ssh key is set
  ];

  networking.hostName = "hanamizuki";

  sdImage.compressImage = false;
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_CA.UTF-8";

  users.users.kiyurica.initialHashedPassword = "$y$j9T$r/9ISSlgIUiqEn1WxadQN0$gdw5OT4nVHOkyhvn86RwsLl/CPxiTIJFaQEkNvmGw.B";
  system.stateVersion = "24.11";
}

