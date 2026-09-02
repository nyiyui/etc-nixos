# A NixOS Module for Appliance Image-based Deployment of NixOS

In short, this module sets up a NixOS configuration that had a read-only root
filesystem and updates with A/B partitions. It's also designed to be used with
systemd-boot(7) and Secure Boot to ensure that the system you are booting has
not been tampered with.

## Motivation

The default NixOS configuration writes your OS configuration to
one Nix store (at `/nix/store`). Naturally, to protect against
tampering of the system or disk, Secure Boot has to be enabled using
[Lanzaboote](https://github.com/nix-community/lanzaboote). However, there are a
few caveats with this approach:

- Generally requires Secure Boot keys to reside on the host [^1]
- Does not protect the root disk from tampering [^2]

[^1]: I believe it's not impossible to sign and install on a build-only machine
      and then copy it over, but it's not the expected usage.
[^2]: I think most people encrypt their root disks for this, but this means that
      boot is stalled until you enter your TPM PIN or disk encryption passphrase
      (if the disk is automatically unlocked without a TPM PIN, you are relying
      on Linux's absence of local privilege escalation attacks, which is, uh,
      not as good these days as of fall 2026).

It also prevents a corruption of the Nix store from bricking your system (which I have only experienced twice in approx. five years, but zero is better than two).

## Setup

**Note: you must have Secure Boot and a BIOS password for your root disk to be
tamper-resistant!** In particular…
- your BIOS password (or similar) ensures that your Secure Boot settings are in place
- Secure Boot ensures that the bootloader (systemd-boot in this case) and the
  executable (UKI in this case) that is being loaded is secure (i.e., signed by
  you)
- the UKI secures the root disk (cf. `roothash=` kernel cmdline)

So if your system doesn't have a BIOS password (or any similar mechanism to keep
your firmware secure), you cannot secure anything that runs on your system with
this module.

This module does not have a `.enable` option for simplicity.

In addition to importing this module, the `boot.initrd.systemd.repart.device`
option must be set to a path to the root device that the "root" partitions
and UKIs are installed in. This is usually where your EFI system partition is,
unless you have multiple (and if that is the case, it's assumed that you know
what you are doing).

Aside: what is a unified kernel image (UKI)? Traditionally, Linux had two files
required to boot, a Kernel executable (e.g., named `vmlinuz`) and an initial
ramdisk image ("initrd") which contained the absolute minimum files required to
find your root disk. A UKI is the combination of those two, so instead of two
files, just one is needed. Having one file is convenient for Secure Boot since
you only need to sign (and verify the signature of) one file instead of two.

While it is possible to install this on an existing configuration, it's
recommended to install this afresh as that is the easiest method to do so.

Build
`<flake>#nixosConfigurations.<name>.config.system.build.sysupdate-package`.
There will be four files in the build result:
- `SHA256SUMS` containing the SHA-256 sums of the other three files
- `assr-appliance-uki_<version>.efi`, the UKI with the root hash of the verity
  partition
- `assr-appliance_<version>.root-verity.<verity-root-hash>.raw`, the verity
  partition, which basically a hash of the contents of the root partition
- `assr-appliance_<version>.root.<hash>.raw`, the root partition (not initrd,
  that is in the UKI)

Initially, you can use systemd-repart(8) to make a full disk image (i.e., one
that you can directly flash to an SSD):
```
nix build <flake>#nixosConfigurations.<name>.config.system.build.image
```
**However,** after flashing the image to an SSD, you must sign the UKI in the
EFI system partition yourself.

## Updating

On subsequent updates, you can use systemd-sysupdate(8) to flash your new
generation (UKI, verity partition, and root partition) to the running system
without touching the currently-running code. First copy the contents of
`sysupdate-package` to `/var/lib/updates` (with the UKI signed with your Secure
Boot key) and then run `updatectl update`.

## Notes

Some notes from writing this module:

`repart.nix` specifies how to make an image of the OS: UKI (`*.efi`),
root partition, and verity hash partition of the root. It also tells the
OS to run systemd-repart(8) to update the partition table to match the
config specified (`systemd.repart.partitions`, not to be confused with
`image.repart.partitions`). Although it's named `root`, the partition only
contains `/nix/store` and `/` is a tmpfs, since some NixOS things assume `/` is
writable (at least in initrd).
