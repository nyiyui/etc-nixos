# SolidWorks VM Configuration

This configuration creates a declarative libvirt domain for running SolidWorks in a VM with workarounds to hide the hypervisor detection.

## Problem

SolidWorks refuses to run in VMs, showing an error message in Japanese that indicates it cannot use a SolidNetwork License (SNL) in a virtual environment.

## Solution

The workaround involves:
1. Creating a declarative libvirt domain with specific features
2. Hiding the KVM hypervisor using the `<hidden state='on'/>` flag
3. Setting a custom vendor_id to mimic physical hardware
4. Disabling the hypervisor CPU feature

## Usage

### Basic Usage (Default Configuration)

The module is enabled by default in `virt.nix`:

```nix
virtualisation.libvirtd.solidworks.enable = true;
```

This will automatically define a VM named "solidworks-vm" at boot using the default configuration in `solidworks-vm-default.xml`.

### Custom Configuration

To use your own domain XML configuration, override the `domainConfig` option:

```nix
virtualisation.libvirtd.solidworks = {
  enable = true;
  domainConfig = ./my-custom-solidworks-vm.xml;
};
```

Your custom XML file should include the hypervisor hiding features. See `solidworks-vm-default.xml` for a reference.

### After System Rebuild

1. The domain will be automatically defined at boot as `solidworks-vm`
2. Use virt-manager to:
   - Attach a disk image for Windows installation
   - Configure GPU passthrough if desired
   - Adjust memory/CPU allocation
   - Start the VM

## Key Configuration Elements

The default configuration includes these essential hypervisor hiding features:

### Hypervisor Hiding
```xml
<hyperv mode='custom'>
  <vendor_id state='on' value='GenuineIntel'/>
  <hidden state='on'/>
</hyperv>
<kvm>
  <hidden state='on'/>
</kvm>
```

### CPU Configuration
```xml
<cpu mode='host-passthrough' check='none' migratable='on'>
  <feature policy='disable' name='hypervisor'/>
</cpu>
```

## Customization

The default domain configuration (`solidworks-vm-default.xml`) provides a basic setup:
- 8GB RAM (configurable)
- 4 CPU cores (configurable)
- Q35 machine type
- No disk attached (you must add this)
- SPICE graphics (can be replaced with GPU passthrough)

To customize, either:
1. Edit the VM after it's defined using `virsh edit solidworks-vm` or virt-manager
2. Create your own XML file and set `domainConfig` to point to it

## References

- https://outerrim.dev/posts/solidworks-vm/ - Original workaround guide
- https://github.com/nyiyui/etc-nixos/issues/28 - Related issue
