{ config, lib, pkgs, ... }:

{
  # Declarative libvirt domain configuration for SolidWorks
  # This includes workarounds to hide the hypervisor from SolidWorks
  
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
        ${pkgs.libvirt}/bin/virsh define ${pkgs.writeText "solidworks-vm.xml" ''
          <domain type='kvm'>
            <name>solidworks-vm</name>
            <uuid>00000000-0000-0000-0000-000000000001</uuid>
            <metadata>
              <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
                <libosinfo:os id="http://microsoft.com/win/11"/>
              </libosinfo:libosinfo>
            </metadata>
            <memory unit='GiB'>8</memory>
            <currentMemory unit='GiB'>8</currentMemory>
            <vcpu placement='static'>4</vcpu>
            <os>
              <type arch='x86_64' machine='q35'>hvm</type>
              <boot dev='hd'/>
            </os>
            <features>
              <acpi/>
              <apic/>
              <hyperv mode='custom'>
                <relaxed state='on'/>
                <vapic state='on'/>
                <spinlocks state='on' retries='8191'/>
                <vendor_id state='on' value='GenuineIntel'/>
                <!-- This is the key workaround: hide the hypervisor -->
                <hidden state='on'/>
              </hyperv>
              <kvm>
                <!-- Additional KVM hiding -->
                <hidden state='on'/>
              </kvm>
              <vmport state='off'/>
            </features>
            <cpu mode='host-passthrough' check='none' migratable='on'>
              <topology sockets='1' dies='1' cores='4' threads='1'/>
              <feature policy='disable' name='hypervisor'/>
            </cpu>
            <clock offset='localtime'>
              <timer name='rtc' tickpolicy='catchup'/>
              <timer name='pit' tickpolicy='delay'/>
              <timer name='hpet' present='no'/>
              <timer name='hypervclock' present='yes'/>
            </clock>
            <on_poweroff>destroy</on_poweroff>
            <on_reboot>restart</on_reboot>
            <on_crash>destroy</on_crash>
            <pm>
              <suspend-to-mem enabled='no'/>
              <suspend-to-disk enabled='no'/>
            </pm>
            <devices>
              <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
              <!-- Placeholder disk - users should configure their own -->
              <!--
              <disk type='file' device='disk'>
                <driver name='qemu' type='qcow2'/>
                <source file='/var/lib/libvirt/images/solidworks-vm.qcow2'/>
                <target dev='vda' bus='virtio'/>
                <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
              </disk>
              -->
              <controller type='usb' index='0' model='qemu-xhci' ports='15'>
                <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
              </controller>
              <controller type='pci' index='0' model='pcie-root'/>
              <controller type='pci' index='1' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='1' port='0x10'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
              </controller>
              <controller type='pci' index='2' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='2' port='0x11'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
              </controller>
              <controller type='pci' index='3' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='3' port='0x12'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
              </controller>
              <controller type='pci' index='4' model='pcie-root-port'>
                <model name='pcie-root-port'/>
                <target chassis='4' port='0x13'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
              </controller>
              <controller type='sata' index='0'>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
              </controller>
              <interface type='network'>
                <mac address='52:54:00:00:00:01'/>
                <source network='default'/>
                <model type='virtio'/>
                <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
              </interface>
              <serial type='pty'>
                <target type='isa-serial' port='0'>
                  <model name='isa-serial'/>
                </target>
              </serial>
              <console type='pty'>
                <target type='serial' port='0'/>
              </console>
              <channel type='unix'>
                <target type='virtio' name='org.qemu.guest_agent.0'/>
                <address type='virtio-serial' controller='0' bus='0' port='1'/>
              </channel>
              <channel type='spicevmc'>
                <target type='virtio' name='com.redhat.spice.0'/>
                <address type='virtio-serial' controller='0' bus='0' port='2'/>
              </channel>
              <input type='tablet' bus='usb'>
                <address type='usb' bus='0' port='1'/>
              </input>
              <input type='mouse' bus='ps2'/>
              <input type='keyboard' bus='ps2'/>
              <graphics type='spice' autoport='yes'>
                <listen type='address'/>
                <image compression='off'/>
              </graphics>
              <sound model='ich9'>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
              </sound>
              <audio id='1' type='spice'/>
              <video>
                <model type='qxl' ram='65536' vram='65536' vgamem='16384' heads='1' primary='yes'/>
                <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
              </video>
              <redirdev bus='usb' type='spicevmc'>
                <address type='usb' bus='0' port='2'/>
              </redirdev>
              <redirdev bus='usb' type='spicevmc'>
                <address type='usb' bus='0' port='3'/>
              </redirdev>
              <memballoon model='virtio'>
                <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
              </memballoon>
              <rng model='virtio'>
                <backend model='random'>/dev/urandom</backend>
                <address type='pci' domain='0x0000' bus='0x06' slot='0x00' function='0x0'/>
              </rng>
            </devices>
          </domain>
        ''}
      fi
    '';
  };
}
