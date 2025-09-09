import requests
import json
import os
import sys
import time
from datetime import datetime, timezone, timedelta
import datetime as dt
from pathlib import Path
from icalendar import Calendar

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
        cal = Calendar.from_ical(content)
    except Exception:
        return {"text": "📅", "tooltip": "Invalid calendar format", "class": "error"}
    
    events = []
    now = datetime.now(tz=timezone.utc)
    now_tomorrow = now + timedelta(days=1)
    
    for component in cal.walk():
        if component.name == "VEVENT":
            dtstart = component.get('dtstart')
            summary = component.get('summary')
            
            if not (dtstart and summary):
                continue
            start_dt = dtstart.dt
            if hasattr(start_dt, 'date'):
                # It's already a datetime
                assert isinstance(start_dt, datetime)
                start_datetime = start_dt
            else:
                # It's a date, convert to datetime at start of day
                start_datetime = datetime.combine(start_dt, dt.time(0, 0)).astimezone()
            
            if start_datetime > now:
                events.append({
                    'start': start_datetime,
                    'summary': str(summary)
                })
    
    if not events:
        return {"text": "📅", "tooltip": "No upcoming events", "class": "empty"}
    
    # Sort by start time and get the next one
    events = sorted(events, key=lambda x: x['start'])
    next_event = events[0]
    
    # Format the time until event
    time_diff = next_event['start'] - now
    
    if time_diff.days > 0:
        time_str = f"{time_diff.days}d"
    elif time_diff.seconds > 3600:
        hours = time_diff.seconds // 3600
        time_str = f"{hours}h"
    elif time_diff.seconds > 60:
        minutes = time_diff.seconds // 60
        time_str = f"{minutes}m"
    else:
        time_str = "now"
    
    # Format start time
    start_time = next_event['start'].strftime('%H:%M')
    tooltip = '\n'.join(f"{e['start'].strftime('%H:%M')} {e['summary']}" for e in events if e['start'] < now_tomorrow)
    
    return {
        "text": f"in {time_str} / {start_time} {next_event['summary']}",
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
