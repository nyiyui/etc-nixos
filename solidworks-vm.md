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

1. Include `solidworks-vm.nix` in your system configuration (it's already included via `virt.nix`)
2. The domain will be automatically defined at boot as `solidworks-vm`
3. Use virt-manager to:
   - Attach a disk image for Windows installation
   - Configure GPU passthrough if desired
   - Adjust memory/CPU allocation
   - Start the VM

## Key Configuration Elements

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

The default domain configuration provides a basic setup. You'll need to:
- Add your Windows disk image
- Configure appropriate memory (default: 8GB)
- Configure CPU cores (default: 4)
- Optionally set up GPU passthrough for better performance

## References

- https://outerrim.dev/posts/solidworks-vm/ - Original workaround guide
- https://github.com/nyiyui/etc-nixos/issues/[issue-number] - Related issue
