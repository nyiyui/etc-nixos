#!/usr/bin/env bash

nixos-rebuild build --flake .#hinanawi
nix copy --to ssh://cirno.msb.q.nyiyui.ca ./result
nixos-rebuild build --flake .#kotohira
nix copy --to ssh://cirno.msb.q.nyiyui.ca ./result
