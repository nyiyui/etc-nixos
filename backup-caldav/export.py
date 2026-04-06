import os
from pathlib import Path
from urllib.parse import quote

from caldav import DAVClient


url      = os.environ['CALDAV_URL']
username = open(Path(os.environ['CREDENTIALS_DIRECTORY']) / 'username').read().strip()
password = open(Path(os.environ['CREDENTIALS_DIRECTORY']) / 'password').read().strip()
destination = Path(os.environ['DESTINATION'])

client = DAVClient(url=url, username=username, password=password)
principal = client.principal()

print(f'got principal {principal} as {username}')

q = lambda s: quote(s, safe='')

for cal in principal.calendars():
    print(f'=== exporting {cal.name}')
    # objs = cal.events()
    objs = cal.search()
    cal_folder = destination / q(str(cal.name))
    cal_folder.mkdir(exist_ok=True)
    for o in objs:
        with open(cal_folder / f'{q(o.component["UID"])}.ics', 'w') as f:
            f.write(o.data)
