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
  ];

  # https://github.com/NixOS/nixpkgs/issues/123725#issuecomment-1063370870
  boot.kernelParams = lib.mkForce [
    "console=ttyS0,115200n8"
    "console=tty0"
  ];

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
  hardware = {
    bluetooth = {
      package = pkgs.bluez;
      enable = true;
      powerOnBoot = false;
    };
  };
  services.blueman.enable = true;
}
