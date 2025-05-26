{ config, lib, ... }: {
  options.autoUpgrade.directFlake =
    lib.mkEnableOption "use Git flake URI directly";
  config = lib.mkIf config.autoUpgrade.directFlake {
    system.autoUpgrade = {
      enable = true;
      rebootWindow.lower = "01:00";
      rebootWindow.upper = "05:00";
      randomizedDelaySec = "1d";
      persistent = true;
      dates = lib.mkDefault "Fri 02:30";
      flake = "github:nyiyui/etc-nixos";
      allowReboot = true;
    };
    nix.gc = {
      options = "--delete-older-than 14d";
      persistent = true;
      dates = lib.mkDefault "06:00"; # after reboot window
      automatic = true;
      randomizedDelaySec = "1h";
    };
    nix.extraOptions = ''
      !include ${config.age.secrets.nix-conf-access-tokens.path}
    '';
    age.secrets.nix-conf-access-tokens = {
      file = ./secrets/nix-conf-access-tokens-${config.networking.hostName}.age;
      mode = "0440";
    };
  };
}
