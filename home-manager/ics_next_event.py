import requests
import json
import os
import sys
import time
from datetime import datetime, timezone, timedelta
import datetime as dt
from pathlib import Path
from icalendar import Calendar
from dateutil import rrule
from dateutil.tz import gettz

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

def expand_recurring_event(component, start_date, end_date):
    """Expand a recurring event into individual instances within the date range"""
    dtstart = component.get('dtstart')
    summary = component.get('summary')
    rrule_prop = component.get('rrule')
    exdate_prop = component.get('exdate')
    
    if not (dtstart and summary and rrule_prop):
        return []
    
    events = []
    start_dt = dtstart.dt
    
    # Convert date to datetime if needed
    if hasattr(start_dt, 'date'):
        start_datetime = start_dt
    else:
        start_datetime = datetime.combine(start_dt, dt.time(0, 0)).astimezone()
    
    try:
        # Convert icalendar RRULE to dateutil rrule
        rule_dict = dict(rrule_prop)
        
        # Map icalendar frequency to dateutil frequency
        freq_map = {
            'YEARLY': rrule.YEARLY,
            'MONTHLY': rrule.MONTHLY,
            'WEEKLY': rrule.WEEKLY,
            'DAILY': rrule.DAILY,
            'HOURLY': rrule.HOURLY,
            'MINUTELY': rrule.MINUTELY,
            'SECONDLY': rrule.SECONDLY
        }
        
        freq = freq_map.get(str(rule_dict.get('FREQ', ['WEEKLY'])[0]), rrule.WEEKLY)
        
        # Create rrule with basic parameters
        rule_kwargs = {'freq': freq, 'dtstart': start_datetime}
        
        # Add interval if specified
        if 'INTERVAL' in rule_dict:
            rule_kwargs['interval'] = int(rule_dict['INTERVAL'][0])
            
        # Add count if specified
        if 'COUNT' in rule_dict:
            rule_kwargs['count'] = int(rule_dict['COUNT'][0])
            
        # Add until if specified
        if 'UNTIL' in rule_dict:
            until_val = rule_dict['UNTIL'][0]
            if isinstance(until_val, datetime):
                rule_kwargs['until'] = until_val
            elif hasattr(until_val, 'dt'):
                rule_kwargs['until'] = until_val.dt
        
        # Add by-rules
        if 'BYDAY' in rule_dict:
            # Handle weekday specifications
            byday = rule_dict['BYDAY']
            if isinstance(byday, list):
                byday = byday[0]
            weekdays = []
            for day in str(byday).split(','):
                day = day.strip().upper()
                if day == 'MO': weekdays.append(rrule.MO)
                elif day == 'TU': weekdays.append(rrule.TU)
                elif day == 'WE': weekdays.append(rrule.WE)
                elif day == 'TH': weekdays.append(rrule.TH)
                elif day == 'FR': weekdays.append(rrule.FR)
                elif day == 'SA': weekdays.append(rrule.SA)
                elif day == 'SU': weekdays.append(rrule.SU)
            if weekdays:
                rule_kwargs['byweekday'] = weekdays
        
        # Create the rrule
        rule = rrule.rrule(**rule_kwargs)
        
        # Collect exception dates (EXDATE)
        exception_dates = set()
        if exdate_prop:
            if hasattr(exdate_prop, '__iter__') and not isinstance(exdate_prop, str):
                # Multiple EXDATE entries
                for exdate in exdate_prop:
                    if hasattr(exdate, 'dts'):
                        for dt_val in exdate.dts:
                            exception_dates.add(dt_val.dt)
                    elif hasattr(exdate, 'dt'):
                        exception_dates.add(exdate.dt)
            else:
                # Single EXDATE entry
                if hasattr(exdate_prop, 'dts'):
                    for dt_val in exdate_prop.dts:
                        exception_dates.add(dt_val.dt)
                elif hasattr(exdate_prop, 'dt'):
                    exception_dates.add(exdate_prop.dt)
        
        # Generate occurrences within our date range, excluding exception dates
        for occurrence in rule:
            if occurrence >= start_date and occurrence <= end_date:
                # Check if this occurrence is excluded by EXDATE
                is_excluded = False
                for exc_date in exception_dates:
                    if hasattr(exc_date, 'date'):
                        exc_datetime = exc_date
                    else:
                        exc_datetime = datetime.combine(exc_date, dt.time(0, 0)).astimezone()
                    
                    if abs((occurrence - exc_datetime).total_seconds()) < 86400:  # Within 1 day
                        is_excluded = True
                        break
                
                if not is_excluded:
                    events.append({
                        'start': occurrence,
                        'summary': str(summary)
                    })
            elif occurrence > end_date:
                break
                
    except Exception as e:
        # If rrule parsing fails, fall back to single event
        if start_datetime >= start_date and start_datetime <= end_date:
            events.append({
                'start': start_datetime,
                'summary': str(summary)
            })
    
    return events

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
    # Look ahead up to 1 year for recurring events
    future_limit = now + timedelta(days=365)
    
    for component in cal.walk():
        if component.name == "VEVENT":
            dtstart = component.get('dtstart')
            summary = component.get('summary')
            rrule_prop = component.get('rrule')
            
            if not (dtstart and summary):
                continue
            
            # Handle recurring events
            if rrule_prop:
                recurring_events = expand_recurring_event(component, now, future_limit)
                events.extend(recurring_events)
            else:
                # Handle single events
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
