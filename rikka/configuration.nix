{ pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/google-compute-image.nix")
    ./autoUpgrade.nix
    ./doas.nix
  ];

  networking.hostName = "rikka";

  system.stateVersion = "23.05";

  users.groups.nyiyui = { };
  users.users.nyiyui = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "nyiyui";
    extraGroups = [ "wheel" ];
    packages = with pkgs; [ firefox chromium syncthing git ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.shells = [ pkgs.fish ];
  nix.settings.auto-optimise-store = true;
}
