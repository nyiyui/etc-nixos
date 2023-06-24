Temporarily disable lid switch:
systemd-inhibit --what=handle-lid-switch sleep 10s
https://unix.stackexchange.com/a/285568

Delete generations (from /boot too):
nix-env -p /nix/var/nix/profiles/system --delete-generations +2
(see https://discourse.nixos.org/t/what-to-do-with-a-full-boot-partition/2049/3)
