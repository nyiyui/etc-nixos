{ pkgs, ... }:
{
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
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBHIr5uQCGECocHl3JKYH9etRA0NOdg9N9+d9ElgPYuCT+Iw3yeA+GAcArfPADxfSqjhpITPJkxWsSdaNmKLrgpA= kiyurica@suzaku.dev.kiyuri.ca"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNAOclCrjD6mtga3MNTjuwveU2/HyTukLACA7KIX1v0OyNW/GBaXHSJ4OikzNURUrhVUbQtfEtAiMlfYiLnPEQw= pixel-6a"
    ];
    homeMode = "770";
  };
  users.users.root.initialHashedPassword = "$y$j9T$hIH10tdwuxQdhSkN6D9vb0$dKJd1SITL.iGfrn8soMLLNyQxvoM0o0MIrmuS.6HuA7";

  nix.settings.trusted-users = [ "kiyurica" ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
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
