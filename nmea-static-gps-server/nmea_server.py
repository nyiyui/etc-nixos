#!/usr/bin/env python3
"""
NMEA static GPS server — broadcasts a fixed position over TCP.

Copied from https://github.com/evert/nmea-static-gps-server/blob/cb2e67796026a7250c91e89834ece3618500954b/nmea_server.py

Configuration (in order of precedence):
  1. Environment variables: NMEA_LAT, NMEA_LON, NMEA_ALT, NMEA_PORT
  2. Config file: nmea.conf (or path in NMEA_CONF env var)

Clients connect via TCP (default port 10110) and receive GPRMC + GPGGA
sentences once per second.

mDNS discovery: drop nmea-static.avahi.xml into /etc/avahi/services/ so
Avahi advertises the service and resolves the hostname correctly for clients
like GeoClue.
"""

import math
import os
import signal
import socket
import threading
import time
from datetime import datetime, timezone

DEFAULT_PORT = 10110
DEFAULT_ALT  = 0.0


# ── config ────────────────────────────────────────────────────────────────────

def _parse_conf(path: str) -> dict:
    cfg = {}
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' not in line:
                continue
            key, _, val = line.partition('=')
            cfg[key.strip()] = val.strip()
    return cfg


def load_config() -> dict:
    lat = os.environ.get('NMEA_LAT')
    lon = os.environ.get('NMEA_LON')

    if lat and lon:
        return {
            'lat':  float(lat),
            'lon':  float(lon),
            'alt':  float(os.environ.get('NMEA_ALT', DEFAULT_ALT)),
            'port': int(os.environ.get('NMEA_PORT', DEFAULT_PORT)),
        }

    conf_path = os.environ.get('NMEA_CONF', 'nmea.conf')
    if os.path.exists(conf_path):
        raw = _parse_conf(conf_path)
        return {
            'lat':  float(raw['lat']),
            'lon':  float(raw['lon']),
            'alt':  float(raw.get('alt', DEFAULT_ALT)),
            'port': int(raw.get('port', DEFAULT_PORT)),
        }

    raise SystemExit(
        "No GPS coordinates found.\n"
        "  Set NMEA_LAT and NMEA_LON environment variables, or\n"
        "  create nmea.conf with lat=, lon=, (optional) alt= and port=."
    )


# ── NMEA sentence builders ────────────────────────────────────────────────────

def _checksum(body: str) -> str:
    cs = 0
    for ch in body:
        cs ^= ord(ch)
    return f'{cs:02X}'


def _sentence(body: str) -> str:
    return f'${body}*{_checksum(body)}\r\n'


def _to_nmea_lat(deg: float) -> tuple[str, str]:
    hemi = 'N' if deg >= 0 else 'S'
    deg  = abs(deg)
    d    = math.floor(deg)
    m    = (deg - d) * 60
    return f'{d:02d}{m:07.4f}', hemi


def _to_nmea_lon(deg: float) -> tuple[str, str]:
    hemi = 'E' if deg >= 0 else 'W'
    deg  = abs(deg)
    d    = math.floor(deg)
    m    = (deg - d) * 60
    return f'{d:03d}{m:07.4f}', hemi


def build_sentences(lat: float, lon: float, alt: float) -> list[str]:
    now      = datetime.now(timezone.utc)
    time_str = now.strftime('%H%M%S.000')
    date_str = now.strftime('%d%m%y')

    lat_s, lat_h = _to_nmea_lat(lat)
    lon_s, lon_h = _to_nmea_lon(lon)

    rmc = f'GPRMC,{time_str},A,{lat_s},{lat_h},{lon_s},{lon_h},0.000,0.000,{date_str},,'
    gga = f'GPGGA,{time_str},{lat_s},{lat_h},{lon_s},{lon_h},1,08,1.0,{alt:.1f},M,0.0,M,,'

    return [_sentence(rmc), _sentence(gga)]


# ── TCP server ────────────────────────────────────────────────────────────────

class NMEAServer:
    def __init__(self, cfg: dict):
        self.lat   = cfg['lat']
        self.lon   = cfg['lon']
        self.alt   = cfg['alt']
        self.port  = cfg['port']
        self._lock    = threading.Lock()
        self._clients: set[socket.socket] = set()

    def _add(self, conn: socket.socket):
        with self._lock:
            self._clients.add(conn)

    def _remove(self, conn: socket.socket):
        with self._lock:
            self._clients.discard(conn)

    def _broadcast(self, data: bytes):
        with self._lock:
            dead = set()
            for conn in self._clients:
                try:
                    conn.sendall(data)
                except OSError:
                    dead.add(conn)
            for conn in dead:
                conn.close()
                self._clients.discard(conn)

    def _broadcast_loop(self):
        while True:
            sentences = build_sentences(self.lat, self.lon, self.alt)
            payload   = ''.join(sentences).encode()
            self._broadcast(payload)
            time.sleep(1.0)

    def _handle(self, conn: socket.socket, addr):
        print(f'client connected: {addr[0]}:{addr[1]}')
        self._add(conn)
        try:
            while True:
                conn.settimeout(30.0)
                data = conn.recv(64)
                if not data:
                    break
        except OSError:
            pass
        finally:
            self._remove(conn)
            conn.close()
            print(f'client disconnected: {addr[0]}:{addr[1]}')

    def serve(self):
        print(f'Static position: lat={self.lat:.6f}  lon={self.lon:.6f}  alt={self.alt:.1f}m')

        def _shutdown(signum, frame):
            raise SystemExit(0)

        signal.signal(signal.SIGTERM, _shutdown)
        signal.signal(signal.SIGINT, _shutdown)

        threading.Thread(target=self._broadcast_loop, daemon=True).start()

        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
            srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            srv.bind(('', self.port))
            srv.listen()
            print(f'NMEA server listening on port {self.port}')
            while True:
                conn, addr = srv.accept()
                threading.Thread(target=self._handle, args=(conn, addr), daemon=True).start()


if __name__ == '__main__':
    cfg = load_config()
    NMEAServer(cfg).serve()
