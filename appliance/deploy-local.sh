#!/usr/bin/env dash

nix build .#nixosConfigurations.suzaku.config.system.build.sysupdate-package
local UKI_UNSIGNED="result/assr-appliance-uki_*.efi"
local UKI_SIGNED="$(basename "$UKI_UNSIGNED")"
sbctl sign "$UKI_UNSIGNED" -o "$UKI_SIGNED"
# NOTE: for server uploads, SHA256SUMS must be updated to match signed UKI
run0 install -D -o root -g root result/assr-appliance_*.root.raw /var/lib/updates/
run0 install -D -o root -g root result/assr-appliance_*.root-verity.raw /var/lib/updates/
run0 install -D -o root -g root $UKI_SIGNED /var/lib/updates/
