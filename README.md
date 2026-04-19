# NixOS configuration

![screenshot of the desktop with a Firefox window displaying this GitHub, and a taskbar to the right](./screenshot.png)

## mitsu8 / living room TV PC

Main configuration file is `mitsu8/configuration.nix`, and
hardware configuration (e.g. disk partition UUIDs, architecture) is in `mitsu8/hardware-configuration.nix`.
Please add configuration to the main configuration file for most edits.


rclone - config contains access/refresh token, don't save here lol

Temporarily disable lid switch:
systemd-inhibit --what=handle-lid-switch sleep 10s
https://unix.stackexchange.com/a/285568

Delete generations (from /boot too):
nix-env -p /nix/var/nix/profiles/system --delete-generations +2
(see https://discourse.nixos.org/t/what-to-do-with-a-full-boot-partition/2049/3)

Blu-ray https://askubuntu.com/questions/1325752/missing-aacs-configuration-file-error-when-playing-blueray-movies

## Temporary synced symlinks

Use `persisted-symlinks-sync` to create temporary home-directory symlinks that point into synced storage (for example, `~/taxes -> ~/inaba/2026/taxes`).

Create `~/.config/persisted-symlinks.json` (this file is user-managed and not in Nix config):

```json
{
  "links": [
    {
      "link": "~/taxes",
      "target": "~/inaba/2026/taxes",
      "start": "2026-03-01",
      "end": "2026-04-30"
    }
  ]
}
```

Fields:
- `link`: symlink path (must be inside `$HOME`)
- `target`: destination path
- `enabled` (optional): set `false` to disable entry
- `start` / `end` (optional): ISO date (`YYYY-MM-DD`) active window
