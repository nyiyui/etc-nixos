import json
import datetime as dt
import requests
import pytz
from dateutil import parser

r = requests.get('https://maclyonsden.com/api/term/current/schedule?format=json')
r.raise_for_status()
schedule = r.json()
now = dt.datetime.utcnow()
now = pytz.utc.localize(now)
current_index: int = None

for i, period in enumerate(schedule):
    start = parser.parse(period['time']['start'])
    end = parser.parse(period['time']['end'])
    if start <= now < end:
        assert current_index == None
        current_index = i

current = schedule[current_index]
end = parser.parse(current['time']['end'])
delta = end - now
data = dict(
    msg=f'あと{delta.seconds//60:02d}分',
    tooltip=f"{current['course']}",
)
data['class'] = 'metrobar'
print(json.dumps(data))

