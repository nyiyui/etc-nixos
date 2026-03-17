{ pkgs, ... }:
{
  imports = [ ./all-modules.nix ];

  users.groups.kiyurica = { };
  users.users.kiyurica = {
    isNormalUser = true;
    description = "Ken Shibata";
    group = "kiyurica";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEhH+5s0m+lBC898M/nrWREaDblRCPSpL6+9wkoZdel inaba@nyiyui.ca"
      "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPLebITu6vwv0WEqXtnIhPq4hOsmG6nUZIcwWVL/LT9OGt0XR4vWwZBqDAt3tZTapY2d71HRqQL7duTyuCLG1h4= kiyurica@suzaku"
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
  services.openssh.extraConfig = "PerSourcePenalties crash:90s authfail:5s refuseconnection:10s noauth:1s grace-exceeded:10s max:10m min:15s max-sources4:65536 max-sources6:65536 overflow:permissive";

  security.sudo.wheelNeedsPassword = false;

  environment.shells = [ pkgs.fish ];
  programs.git.enable = true;
  programs.tmux.enable = true;
  programs.htop.enable = true;
}
