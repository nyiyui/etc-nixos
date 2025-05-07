{ pkgs, lib, ... }:
{
  environment.systemPackages = [ pkgs.vlc ];
  nixpkgs.overlays = [
    (self: super: {
      libbluray = super.libbluray.override {
        withAACS = true;
        withBDplus = true;
      };
    })
  ];
}
