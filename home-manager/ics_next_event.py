import traceback
import requests
import json
import os
import sys
import time
from datetime import datetime, timezone, timedelta
import datetime as dt
from pathlib import Path
from icalendar import Calendar
from recurring_ical_events import of
from xml.sax.saxutils import escape


# Configuration
CACHE_DIR = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'waybar-ics'
CACHE_DURATION = 3600  # 1 hour in seconds

def fetch_ics(ics_url):
    """Fetch ICS file from URL or use cached version"""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    
    # Create cache filename from URL hash
    import hashlib
    url_hash = hashlib.sha512(ics_url.encode()).hexdigest()
    cache_file = CACHE_DIR / f'events_{url_hash}.ics'
    
    # Check if cache exists and is recent
    if cache_file.exists():
        cache_age = time.time() - cache_file.stat().st_mtime
        if cache_age < CACHE_DURATION:
            try:
                with open(cache_file, 'rb') as f:
                    return f.read()
            except Exception:
                pass
    
    # Try to fetch from URL
    try:
        response = requests.get(ics_url, timeout=10)
        response.raise_for_status()
        content = response.content
        
        # Save to cache
        with open(cache_file, 'wb') as f:
            f.write(content)
        return content
    except requests.RequestException:
        pass
    
    # Fall back to cached version if available
    if cache_file.exists():
        try:
            with open(cache_file, 'rb') as f:
                return f.read()
        except Exception:
            pass
    
    return None

def load_calendar(content):
    """Parse ICS content into a Calendar object"""
    if not content:
        return None
    
    try:
        return Calendar.from_ical(content)
    except Exception:
        traceback.print_exc()
        return None

def get_next_event(calendars):
    """Get the next upcoming event from multiple calendars"""
    now = datetime.now(tz=timezone.utc)
    now_local = now.astimezone()
    system_tz = now_local.tzinfo
    tomorrow = now_local + timedelta(days=1)
    
    upcoming_events = []
    current_events = []
    
    # Process each calendar
    for calendar in calendars:
        # Get events for today and tomorrow, including recurring events
        events_today = of(calendar).at(now_local.date())
        events_tomorrow = of(calendar).at(tomorrow.date())
        all_events = events_today + events_tomorrow
        
        for event in all_events:
            event_start = event.get('dtstart')
            event_end = event.get('dtend')
            if event_start:
                # Convert to datetime if it's a date
                if hasattr(event_start.dt, 'date'):
                    start_dt = event_start.dt
                    # Convert to system timezone if it has timezone info
                    if hasattr(start_dt, 'tzinfo') and start_dt.tzinfo is not None:
                        start_dt = start_dt.astimezone(system_tz)
                else:
                    # It's a date, convert to datetime at start of day
                    start_dt = datetime.combine(event_start.dt, datetime.min.time())
                    start_dt = start_dt.replace(tzinfo=system_tz)
                
                # Handle end time
                end_dt = None
                if event_end:
                    if hasattr(event_end.dt, 'date'):
                        end_dt = event_end.dt
                        if hasattr(end_dt, 'tzinfo') and end_dt.tzinfo is not None:
                            end_dt = end_dt.astimezone(system_tz)
                    else:
                        end_dt = datetime.combine(event_end.dt, datetime.min.time())
                        end_dt = end_dt.replace(tzinfo=system_tz)
                
                summary = str(event.get('summary', 'No title'))
                location = str(event.get('location', '')) if event.get('location') else None
                
                # Check if event is current (started but not ended)
                if start_dt <= now_local and (end_dt is None or end_dt > now_local):
                    current_events.append({
                        'start': start_dt,
                        'end': end_dt,
                        'summary': summary,
                        'location': location
                    })
                elif start_dt > now_local:
                    upcoming_events.append({
                        'start': start_dt,
                        'end': end_dt,
                        'summary': summary,
                        'location': location
                    })
    
    if not upcoming_events:
        return {"text": "📅", "tooltip": "No upcoming events", "class": "empty"}
    
    # Sort by start time and get the next one
    current_events = sorted(current_events, key=lambda x: x['start'])
    upcoming_events = sorted(upcoming_events, key=lambda x: x['start'])
    next_event = upcoming_events[0]
    
    # Format start time - add 24 hours if tomorrow
    event_start = next_event['start']
    if event_start.date() > now_local.date():
        # Tomorrow's event - add 24 to the hour
        hour_24 = event_start.hour + 24
        start_time = f"{hour_24:02d}:{event_start.minute:02d}"
    else:
        start_time = event_start.strftime('%H:%M')
    
    # Format tooltip times - add 24 hours for tomorrow's events
    tooltip_entries = []
    
    # Add current events to tooltip
    for e in current_events:
        time_str = e['start'].strftime('%H:%M')
        entry = f"{time_str} {e['summary']}"
        if e.get('location'):
            entry += f" @ {e['location']}"
        entry += f" (current; ends {e['end'].strftime('%H:%M')})"
        tooltip_entries.append(entry)
    
    # Add upcoming events to tooltip
    for e in upcoming_events:
        if e['start'] < tomorrow:
            if e['start'].date() > now_local.date():
                hour_24 = e['start'].hour + 24
                time_str = f"{hour_24:02d}:{e['start'].minute:02d}"
            else:
                time_str = e['start'].strftime('%H:%M')
            entry = f"{time_str} {e['summary']}"
            if e.get('location'):
                entry += f" @ {e['location']}"
            tooltip_entries.append(entry)
    tooltip = '\n'.join(tooltip_entries)
    
    return {
        "text": escape(f"{start_time} {next_event['summary']}"),
        "tooltip": escape(tooltip),
        "class": "upcoming"
    }

def main():
    if len(sys.argv) != 2:
        print(json.dumps({"text": "📅", "tooltip": f"Usage: {sys.argv[0]} <ICS_URL_FILE>", "class": "error"}))
        return
    
    ics_url_path = sys.argv[1]
    with open(ics_url_path) as f:
        ics_urls = [line.strip() for line in f if line.strip()]
    
    # Fetch and load all calendars
    calendars = []
    for ics_url in ics_urls:
        content = fetch_ics(ics_url)
        calendar = load_calendar(content)
        if calendar:
            calendars.append(calendar)
    
    if not calendars:
        result = {"text": "📅", "tooltip": "No calendar data", "class": "error"}
    else:
        result = get_next_event(calendars)
    print(json.dumps(result))

if __name__ == "__main__":
    main()
