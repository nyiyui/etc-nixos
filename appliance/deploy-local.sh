#!/usr/bin/env dash

set -eux

nix build -L .#nixosConfigurations.suzaku.config.system.build.sysupdate-package
UKI_UNSIGNED="$(echo result/assr-appliance-uki_*.efi)"
BOOTLOADER_UNSIGNED="$(echo result/BOOT*.EFI)"
SIGNED_DIR="$(mktemp -d)"
UKI_SIGNED="$SIGNED_DIR/$(basename "$UKI_UNSIGNED")"
BOOTLOADER_SIGNED="$SIGNED_DIR/$(basename "$BOOTLOADER_UNSIGNED")"
run0 sbctl sign "$UKI_UNSIGNED" -o "$UKI_SIGNED"
run0 sbctl sign "$BOOTLOADER_UNSIGNED" -o "$BOOTLOADER_SIGNED"
# NOTE: for server uploads, SHA256SUMS must be updated to match signed EFI files
run0 install -D -o root -g root result/assr-appliance_*.root.*.raw /var/lib/updates/
run0 install -D -o root -g root result/assr-appliance_*.root-verity.*.raw /var/lib/updates/
run0 install -D -o root -g root "$UKI_SIGNED" /var/lib/updates/
run0 install -D -o root -g root "$BOOTLOADER_SIGNED" /var/lib/updates/
