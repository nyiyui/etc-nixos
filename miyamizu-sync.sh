#!/usr/bin/env bash

set -euo pipefail

hosts=(kotohira hinanawi)

for host in "${hosts[@]}"; do
  #options="--flake '.#$host' --target-host '$host.msb.q.nyiyui.ca' --use-remote-sudo"
  ssh "$host.msb.q.nyiyui.ca" -- 'sudo nix-collect-garbage'
  #nixos-rebuild build $options
  deploy ".#$host"
  ssh "$host.msb.q.nyiyui.ca" -- ' nix-env --delete-generations 1d'
  ssh "$host.msb.q.nyiyui.ca" -- 'sudo nix-collect-garbage -d'
done
