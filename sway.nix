{ ... }: {
  programs.sway.enable = true;
  home-manager.users.nyiyui = {
    imports = [ ./nyiyui/graphical.nix ./nyiyui/sway.nix ];
  };
  services.xserver.displayManager.defaultSession = "sway";
}
