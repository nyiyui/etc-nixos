{ specialArgs, ... }:
{
  programs.niri.enable = true;
  nixpkgs.overlays = [ specialArgs.niri.overlays.niri ];
  home-manager.users.nyiyui = {
    imports = [
      ./nyiyui/graphical.nix
      ./nyiyui/niri
    ];
  };
  services.xserver.displayManager.defaultSession = "niri";
}
