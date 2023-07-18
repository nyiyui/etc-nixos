{ pkgs, ... }: {
  imports = [ ./miyamizu.nix ];
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
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nixpkgs.config.allowUnfree = true;

  services.openssh.enable = true;

  # required for nixos-rebuild switch --use-remote-sudo to work
  security.sudo.wheelNeedsPassword = false;
  security.doas.enable = true;
  security.doas.extraRules = [{
    users = [ "nyiyui" ];
    keepEnv = true;
    noPass = true;
  }];

  environment.shells = [ pkgs.fish ];
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.htop.enable = true;
}
