{ pkgs, ... }: {
  virtualisation.libvirtd.enable = true;
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager ];
  users.users.nyiyui.extraGroups = [ "libvirtd" ];
}
