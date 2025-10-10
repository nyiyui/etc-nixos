{ pkgs, ... }:
{
  imports = [
    ./solidworks-vm.nix
  ];

  virtualisation.libvirtd = {
    enable = true;
    solidworks.enable = true;
  };
  
  programs.dconf.enable = true;
  environment.systemPackages = with pkgs; [ virt-manager ];
  users.users.kiyurica.extraGroups = [ "libvirtd" ];
}
