#!/usr/bin/env dash

nix build .#nixosConfigurations.suzaku.config.system.build.sysupdate-package
run0 install -D -o root -g root result/assr-appliance* /var/lib/updates/
