{ pkgs, ... }: {
  imports = [ ./all-modules.nix ];

  users.groups.kiyurica = { };
  users.users.kiyurica = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "kiyurica";
    extraGroups = [ "wheel" ];
    packages = with pkgs; [ git ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEhH+5s0m+lBC898M/nrWREaDblRCPSpL6+9wkoZdel inaba@nyiyui.ca"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBF4Ojz3i6fCU8n86+9oFnfC+rCjoufNMvwjjBppJZBN6t79Y0U+yrWzEnaQ7I9enXOZO9V1Ostje6y2Kv4N+tcQ= nyiyui@hinanawi.dev.kiyuri.ca"
    ];
    homeMode = "770";
  };

  nix.settings.trusted-users = [ "kiyurica" ];
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
