{ ... }: {
  system.autoUpgrade = {
    enable = true;
    rebootWindow.lower = "03:00";
    rebootWindow.upper = "05:00";
    randomizedDelaySec = "1h";
    persistent = true;
    flake = "/etc/nixos";
    allowReboot = true;
  };
  nix.gc = {
    options = "--delete-older-than 14d";
    persistent = true;
    dates = "06:00"; # after reboot window
    automatic = true;
    randomizedDelaySec = "1h";
  };
}
