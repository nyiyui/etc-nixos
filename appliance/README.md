Modules for a NixOS setup using images (v. generations) and A/B partitions.

```sh
nix build .#nixosConfigurations.deviceName.config.system.build.sysupdate-package
```

`repart.nix` specifies how to make an image of the OS: UKI (`*.efi`), root partition, and verity hash partition of the root.
It also tells the OS to run systemd-repart(8) to update the partition table to match the config specified (`systemd.repart.partitions`, not to be confused with `image.repart.partitions`).
Although it's named `root`, the partition only contains `/nix/store` and `/` is a tmpfs, since some NixOS things assume `/` is writable (at least in initrd).
