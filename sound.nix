{ pkgs, ... }: {
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  home-manager.users.nyiyui = {
    imports = [ ({ pkgs, ... }: { home.packages = [ pkgs.qpwgraph ]; }) ];
  };
}
