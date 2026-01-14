#!/usr/bin/env python3
"""
Sync Canvas .ics calendar entries to a CalDAV task list as VTODOs.

Notes:
- Requires: caldav, icalendar
- Duplicates avoided via UID prefix "canvas-evt-".
"""

import os
import sys
import logging
import argparse
import re
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, List, Optional

from caldav import DAVClient
from caldav.objects import Todo
from icalendar import Calendar, Todo as IcalTodo

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")


parser = argparse.ArgumentParser(description="Sync Canvas .ics to CalDAV VTODOs")
parser.add_argument("--ics-path", required=True, help="Path to Canvas .ics file")
parser.add_argument("--caldav-url", help="CalDAV server URL")
parser.add_argument("--caldav-username", help="CalDAV username")
parser.add_argument("--caldav-password", help="CalDAV password")
parser.add_argument("--tasklist-name", help="CalDAV task list/calendar name")
parser.add_argument(
    "--dry-run", action="store_true", help="Print actions without modifying server"
)
parser.add_argument(
    "--uid-filter", help="Regex to include only VEVENTs whose UID matches"
)
args = parser.parse_args()

CALDAV_URL = args.caldav_url
CALDAV_USERNAME = args.caldav_username
CALDAV_PASSWORD = args.caldav_password or os.environ.get("CALDAV_PASSWORD")
CALDAV_TASKLIST_NAME = args.tasklist_name
CANVAS_ICS_PATH = args.ics_path
DRY_RUN = args.dry_run
UID_FILTER = args.uid_filter

# Validate required inputs
if not DRY_RUN and not (CALDAV_URL and CALDAV_USERNAME and CALDAV_PASSWORD):
    print(
        "Error: Provide --caldav-url, --caldav-username, --caldav-password (or use --dry-run)",
        file=sys.stderr,
    )
    sys.exit(2)


def ensure_tasklist(principal) -> Any:
    """Find or create a CalDAV task-capable calendar (task list)."""
    # Some servers expose task lists via principal.calendars(); others via principal.tasklists().
    tasklists = []
    if hasattr(principal, "tasklists"):
        try:
            tasklists = principal.tasklists()
        except Exception:
            tasklists = []
    if not tasklists:
        try:
            tasklists = [
                c
                for c in principal.calendars()
                if "VTODO"
                in (getattr(c, "supported_components", []) or ["VTODO", "VEVENT"])
            ]
        except Exception:
            tasklists = principal.calendars()
    if CALDAV_TASKLIST_NAME:
        for c in tasklists:
            try:
                name = c.name
            except Exception:
                name = None
            if name == CALDAV_TASKLIST_NAME:
                return c
        raise RuntimeError(f"Task list '{CALDAV_TASKLIST_NAME}' not found")
    # Fallback: first available
    if not tasklists:
        raise RuntimeError("No CalDAV calendars/task lists found for VTODO")
    return tasklists[0]


def ical_vtodo_from_vevent(event) -> Optional[IcalTodo]:
    try:
        uid = str(event.get("uid"))
    except Exception:
        uid = None
    if not uid:
        return None
    summary = str(event.get("summary") or "Canvas Task")
    url = str(event.get("url") or "")
    desc = event.get("description")
    dtstart = event.get("dtstart")
    dtend = event.get("dtend")

    vtodo = IcalTodo()
    vtodo.add("uid", f"canvas-evt-{uid}")
    vtodo.add("summary", summary)
    if url:
        vtodo.add("url", url)
    # Prefer due from dtend if present, else dtstart
    try:
        if dtend and getattr(dtend, "dt", None):
            vtodo.add("due", dtend.dt)
        elif dtstart and getattr(dtstart, "dt", None):
            vtodo.add("due", dtstart.dt)
            if hasattr(dtstart.dt, "hour"):
                vtodo.add("dtstart", dtstart.dt)
    except Exception:
        pass
    vtodo.add("status", "NEEDS-ACTION")
    vtodo.add("categories", ["Canvas"])
    if desc:
        try:
            vtodo.add("description", str(desc))
        except Exception:
            pass
    return vtodo


def wrap_vcalendar(vtodo: IcalTodo) -> bytes:
    cal = Calendar()
    cal.add("prodid", "-//canvas-to-caldav//")
    cal.add("version", "2.0")
    cal.add_component(vtodo)
    return cal.to_ical()


def vtodo_changed(old_comp, new_vtodo) -> bool:
    print('changed', old_comp, new_vtodo)
    def get_str(comp, key):
        val = comp.get(key)
        # icalendar may return vCalAddress, vText, vDatetime; convert safely
        try:
            if hasattr(val, "to_ical"):
                return val.to_ical()
            if hasattr(val, "dt"):
                return val.dt
            return str(val) if val is not None else None
        except Exception:
            return str(val) if val is not None else None

    keys = ["summary", "url", "description", "due", "dtstart"]
    for k in keys:
        old_v = get_str(old_comp, k)
        new_v = get_str(new_vtodo, k)
        if old_v != new_v:
            return True
    return False


def existing_uids(tasklist) -> set:
    uids = set()
    try:
        todos = tasklist.todos()
    except Exception:
        try:
            todos = tasklist.objects
        except Exception:
            todos = []
    for t in todos:
        try:
            ical = t.icalendar_instance
            vtodo = getattr(ical, "vtodo", None)
            if vtodo:
                uid = str(vtodo.get("uid"))
                if uid:
                    uids.add(uid)
        except Exception:
            # Fallback parse raw
            try:
                raw = t.data if hasattr(t, "data") else None
                if raw:
                    cal = Calendar.from_ical(raw)
                    for comp in cal.subcomponents:
                        if comp.name == "VTODO":
                            uid = str(comp.get("uid"))
                            if uid:
                                uids.add(uid)
            except Exception:
                continue
    return uids


def existing_vtodo_components(tasklist) -> dict:
    comps = {}
    try:
        todos = tasklist.todos()
    except Exception:
        try:
            todos = tasklist.objects
        except Exception:
            todos = []
    for t in todos:
        raw = getattr(t, "data", None)
        if not raw:
            # Try icalendar_instance
            try:
                ical = t.icalendar_instance
                vtodo = getattr(ical, "vtodo", None)
                if vtodo:
                    uid = str(vtodo.get("uid"))
                    if uid:
                        comps[uid] = vtodo
                continue
            except Exception:
                pass
        try:
            cal = Calendar.from_ical(raw)
            for comp in cal.subcomponents:
                if comp.name == "VTODO":
                    uid = str(comp.get("uid"))
                    if uid:
                        comps[uid] = comp
        except Exception:
            continue
    return comps


def main():
    if DRY_RUN:
        tasklist = None
        uids = set()
    else:
        client = DAVClient(
            CALDAV_URL, username=CALDAV_USERNAME, password=CALDAV_PASSWORD
        )
        principal = client.principal()
        tasklist = ensure_tasklist(principal)
        uids = existing_uids(tasklist)

    created = 0
    updated = 0

    vtodos: List[IcalTodo] = []
    logging.info(f"Parsing ICS from {CANVAS_ICS_PATH}...")
    with open(CANVAS_ICS_PATH, "rb") as f:
        cal = Calendar.from_ical(f.read())
    for ev in cal.walk("VEVENT"):
        if UID_FILTER:
            try:
                ev_uid = str(ev.get("uid") or "")
            except Exception:
                ev_uid = ""
            if not re.search(UID_FILTER, ev_uid):
                continue
        v = ical_vtodo_from_vevent(ev)
        if v:
            vtodos.append(v)

    for vtodo in vtodos:
        uid = str(vtodo.get("uid"))
        data = wrap_vcalendar(vtodo)
        if uid in uids:
            if DRY_RUN:
                summary = str(vtodo.get("summary") or "")
                due_prop = vtodo.get("due") or vtodo.get("dtstart")
                try:
                    due_dt = getattr(due_prop, "dt", due_prop)
                except Exception:
                    due_dt = None
                due_str = (
                    due_dt.isoformat()
                    if hasattr(due_dt, "isoformat")
                    else (str(due_dt) if due_dt else "no due date")
                )
                logging.info(
                    f"DRY RUN: Would update task {uid} - {summary} (due {due_str})"
                )
                updated += 1
            else:
                # Attempt update: find and overwrite
                todos = tasklist.todos()
                for t in todos:
                    raw = getattr(t, "data", None)
                    if raw:
                        cal = Calendar.from_ical(raw)
                        for comp in cal.subcomponents:
                            if comp.name == "VTODO" and str(comp.get("uid")) == uid:
                                # Preserve STATUS unless content changed
                                try:
                                    existing_status = comp.get("status")
                                except Exception:
                                    existing_status = None
                                if existing_status and not vtodo_changed(comp, vtodo):
                                    vtodo["status"] = existing_status
                                    data = wrap_vcalendar(vtodo)
                                if hasattr(t, "delete"):
                                    t.delete()
                                tasklist.add_todo(data)
                                updated += 1
                                break
        else:
            if DRY_RUN:
                summary = str(vtodo.get("summary") or "")
                due_prop = vtodo.get("due") or vtodo.get("dtstart")
                try:
                    due_dt = getattr(due_prop, "dt", due_prop)
                except Exception:
                    due_dt = None
                due_str = (
                    due_dt.isoformat()
                    if hasattr(due_dt, "isoformat")
                    else (str(due_dt) if due_dt else "no due date")
                )
                logging.info(
                    f"DRY RUN: Would create task {uid} - {summary} (due {due_str})"
                )
                created += 1
            else:
                tasklist.add_todo(data)
                created += 1

    logging.info(
        f"Sync complete. Created: {created}, Updated: {updated}, Total items processed: {len(vtodos)}"
    )


if __name__ == "__main__":
    main()
