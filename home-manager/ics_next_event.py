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

# Configuration
CACHE_DIR = Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'waybar-ics'
CACHE_DURATION = 3600  # 1 hour in seconds

def fetch_ics(ics_url):
    """Fetch ICS file from URL or use cached version"""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    
    # Create cache filename from URL hash
    import hashlib
    url_hash = hashlib.md5(ics_url.encode()).hexdigest()
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

def get_next_event(ics_url):
    """Get the next upcoming event"""
    content = fetch_ics(ics_url)
    if not content:
        return {"text": "📅", "tooltip": "No calendar data", "class": "error"}
    
    try:
        calendar = Calendar.from_ical(content)
    except Exception:
        traceback.print_exc()
        return {"text": "📅", "tooltip": "Invalid calendar format", "class": "error"}
    
    now = datetime.now(tz=timezone.utc)
    now_local = now.astimezone()
    tomorrow = now_local + timedelta(days=1)
    
    # Get events for today and tomorrow, including recurring events
    events_today = of(calendar).at(now_local.date())
    events_tomorrow = of(calendar).at(tomorrow.date())
    all_events = events_today + events_tomorrow
    
    upcoming_events = []
    for event in all_events:
        event_start = event.get('dtstart')
        if event_start:
            # Convert to datetime if it's a date
            if hasattr(event_start.dt, 'date'):
                start_dt = event_start.dt
            else:
                # It's a date, convert to datetime at start of day
                start_dt = datetime.combine(event_start.dt, datetime.min.time())
                start_dt = start_dt.replace(tzinfo=now_local.tzinfo)
            
            if start_dt > now_local:
                summary = str(event.get('summary', 'No title'))
                upcoming_events.append({
                    'start': start_dt,
                    'summary': summary
                })
    
    if not upcoming_events:
        return {"text": "📅", "tooltip": "No upcoming events", "class": "empty"}
    
    # Sort by start time and get the next one
    upcoming_events = sorted(upcoming_events, key=lambda x: x['start'])
    next_event = upcoming_events[0]
    
    # Format start time
    start_time = next_event['start'].strftime('%H:%M')
    tooltip = '\n'.join(f"{e['start'].strftime('%H:%M')} {e['summary']}" for e in upcoming_events if e['start'] < tomorrow)
    
    return {
        "text": f"{start_time} {next_event['summary']}",
        "tooltip": tooltip,
        "class": "upcoming"
    }

def main():
    if len(sys.argv) != 2:
        print(json.dumps({"text": "📅", "tooltip": f"Usage: {sys.argv[0]} <ICS_URL>", "class": "error"}))
        return
    
    ics_url_path = sys.argv[1]
    with open(ics_url_path) as f:
        ics_url = f.read().strip()
    result = get_next_event(ics_url)
    print(json.dumps(result))

if __name__ == "__main__":
    main()
