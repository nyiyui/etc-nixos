#!/usr/bin/env python3

import argparse
import datetime
import json
import os
import pathlib
import sys


def parse_date(raw):
    if raw is None:
        return None
    if not isinstance(raw, str):
        raise ValueError(f"expected date string, got {type(raw).__name__}")
    return datetime.date.fromisoformat(raw)


def absolute_path(raw, home):
    if not isinstance(raw, str) or raw == "":
        raise ValueError("path must be a non-empty string")
    path = pathlib.Path(os.path.expanduser(raw))
    if not path.is_absolute():
        path = home / path
    return path


def symlink_target(path):
    raw = os.readlink(path)
    target = pathlib.Path(raw)
    if not target.is_absolute():
        target = (path.parent / target).resolve(strict=False)
    else:
        target = target.resolve(strict=False)
    return target


def is_active(entry, today):
    if entry.get("enabled", True) is False:
        return False
    start = parse_date(entry.get("start"))
    end = parse_date(entry.get("end"))
    if start is not None and today < start:
        return False
    if end is not None and today > end:
        return False
    return True


def load_entries(config_path):
    with config_path.open("r", encoding="utf-8") as f:
        loaded = json.load(f)

    if isinstance(loaded, list):
        return loaded
    if isinstance(loaded, dict) and isinstance(loaded.get("links"), list):
        return loaded["links"]
    raise ValueError("config must be a list or an object with a 'links' list")


def main():
    parser = argparse.ArgumentParser(
        description="Create symlinks in $HOME from a user-managed JSON config."
    )
    parser.add_argument(
        "--config",
        default="~/.config/persisted-symlinks.json",
        help="JSON config path (default: ~/.config/persisted-symlinks.json)",
    )
    parser.add_argument("--dry-run", action="store_true", help="Print actions only")
    args = parser.parse_args()

    home = pathlib.Path.home()
    config_path = pathlib.Path(os.path.expanduser(args.config))
    if not config_path.exists():
        print(f"persisted-symlinks-sync: config not found: {config_path}", file=sys.stderr)
        return 0

    try:
        entries = load_entries(config_path)
    except Exception as e:
        print(f"persisted-symlinks-sync: failed to read config: {e}", file=sys.stderr)
        return 1

    today = datetime.date.today()
    had_error = False

    for i, entry in enumerate(entries):
        if not isinstance(entry, dict):
            print(f"entry {i}: expected object", file=sys.stderr)
            had_error = True
            continue

        try:
            link = absolute_path(entry["link"], home)
            target = absolute_path(entry["target"], home)
            active = is_active(entry, today)
        except Exception as e:
            print(f"entry {i}: invalid config: {e}", file=sys.stderr)
            had_error = True
            continue

        try:
            link.relative_to(home)
        except ValueError:
            print(f"entry {i}: link path must be inside {home}", file=sys.stderr)
            had_error = True
            continue

        target_resolved = target.resolve(strict=False)

        if active:
            if link.exists() and not link.is_symlink():
                print(f"entry {i}: skipping non-symlink path: {link}", file=sys.stderr)
                had_error = True
                continue
            if link.is_symlink() and symlink_target(link) == target_resolved:
                continue

            if args.dry_run:
                if link.is_symlink():
                    print(f"would replace {link} -> {target}")
                else:
                    print(f"would create {link} -> {target}")
                continue

            link.parent.mkdir(parents=True, exist_ok=True)
            if link.is_symlink():
                link.unlink()
            link.symlink_to(target)
            print(f"linked {link} -> {target}")
            continue

        if link.is_symlink() and symlink_target(link) == target_resolved:
            if args.dry_run:
                print(f"would remove expired link {link}")
            else:
                link.unlink()
                print(f"removed expired link {link}")

    return 1 if had_error else 0


if __name__ == "__main__":
    raise SystemExit(main())
