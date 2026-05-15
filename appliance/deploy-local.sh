#!/usr/bin/env dash

set -eux

nix build -L .#nixosConfigurations.suzaku.config.system.build.sysupdate-package
UKI_UNSIGNED="$(echo result/assr-appliance-uki_*.efi)"
UKI_SIGNED="$(mktemp -d)/$(basename "$UKI_UNSIGNED")"
run0 sbctl sign "$UKI_UNSIGNED" -o "$UKI_SIGNED"
# NOTE: for server uploads, SHA256SUMS must be updated to match signed UKI
run0 install -D -o root -g root result/assr-appliance_*.root.*.raw /var/lib/updates/
run0 install -D -o root -g root result/assr-appliance_*.root-verity.*.raw /var/lib/updates/
run0 install -D -o root -g root $UKI_SIGNED /var/lib/updates/
