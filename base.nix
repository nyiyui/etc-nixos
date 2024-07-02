{ pkgs, ... }: {
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
    homeMode = "770";
  };

  nix.settings.trusted-users = [ "nyiyui" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  services.openssh.enable = true;
  services.fail2ban.enable = true;

  security.sudo.wheelNeedsPassword = false;

  environment.shells = [ pkgs.fish ];
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.htop.enable = true;
}
