{ config, lib, pkgs, ... }:

let
  cfg = config.virtualisation.libvirtd.solidworks;
in
{
  options.virtualisation.libvirtd.solidworks = {
    enable = lib.mkEnableOption "SolidWorks VM with hypervisor hiding";
    
    domainConfig = lib.mkOption {
      type = lib.types.path;
      default = ./solidworks-vm-default.xml;
      description = ''
        Path to the libvirt domain XML configuration file for SolidWorks VM.
        The default configuration includes hypervisor hiding features necessary
        to prevent SolidWorks from detecting the virtual environment.
        
        You can provide your own XML file with custom settings (memory, CPU, disk, etc.)
        but make sure to include the hypervisor hiding features.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    
    # Create a declarative libvirt domain for SolidWorks
    # Note: NixOS doesn't have built-in declarative domain management,
    # so we use systemd to define the domain at boot
    systemd.services.libvirt-solidworks-domain = {
      description = "Define SolidWorks libvirt domain";
      after = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      
      script = ''
        # Define the domain if it doesn't exist
        if ! ${pkgs.libvirt}/bin/virsh list --all --name | grep -q "^solidworks-vm$"; then
          ${pkgs.libvirt}/bin/virsh define ${cfg.domainConfig}
        fi
      '';
    };
  };
}
