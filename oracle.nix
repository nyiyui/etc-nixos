{ pkgs ? import <nixpkgs> { } }:
let config = {
  imports = [ <nixpkgs/nixos/modules/virtualisation/oci-image.nix> ];

  system.stateVersion = "23.11";

  services.openssh.enable = true;
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
  ];
  programs.git.enable = true;
  users.groups.nyiyui = { };
  users.users.nyiyui = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "nyiyui";
    extraGroups = [ "networkmanager" "wheel" "dialout" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEhH+5s0m+lBC898M/nrWREaDblRCPSpL6+9wkoZdel inaba@nyiyui.ca"
    ];
    homeMode = "770";
  };
  nix.settings.trusted-users = [ "nyiyui" ];
  environment.shells = [ pkgs.fish ];
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };
};
in
(pkgs.nixos config).OCIImage

