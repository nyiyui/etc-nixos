{ pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/google-compute-image.nix")
    ../autoUpgrade.nix
    ./kuromiya.nix
    ../kuromiya.nix
  ];

  security.doas.enable = true;
  security.doas.extraRules = [{
    users = [ "nyiyui" ];
    keepEnv = true;
    noPass = true;
  }];

  networking.hostName = "rei";

  system.stateVersion = "23.05";

  users.groups.nyiyui = { };
  users.users.nyiyui = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "nyiyui";
    extraGroups = [ "wheel" ];
    packages = with pkgs; [ git ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEhH+5s0m+lBC898M/nrWREaDblRCPSpL6+9wkoZdel inaba@nyiyui.ca"
    ];
  };
  nix.settings.trusted-users = [ "nyiyui" ];

  environment.systemPackages = with pkgs; [ wireguard-tools ];
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.htop.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.shells = [ pkgs.fish ];
  nix.settings.auto-optimise-store = true;

  qrystal.services.node.config.cs.azusa.networks.msb = {
    host = "rei.nyiyui.ca:39570";
  };
}
