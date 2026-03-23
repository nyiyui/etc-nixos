import asyncio
import subprocess
import sys
import os
from dbus_next.aio import MessageBus
from dbus_next import Variant, BusType

WLSUNSET_BIN = os.environ.get("WLSUNSET_BIN")
if not WLSUNSET_BIN:
    print(
        "Error: WLSUNSET_BIN environment variable is not set.", file=sys.stderr
    )
    sys.exit(1)

proc = None
current_lat_lon = None
extra_args = sys.argv[1:]


def close_enough(a, b):
    # Roughly 11km accuracy, plenty for solar calculations.
    return round(a[0], 1) == round(b[0], 1) and round(a[1], 1) == round(
        b[1], 1
    )


def update_wlsunset(lat, lon):
    global proc, current_lat_lon
    if proc:
        if current_lat_lon and close_enough(current_lat_lon, (lat, lon)):
            return
        print(
            f"Location changed, terminating old wlsunset (PID {proc.pid})",
            file=sys.stderr,
        )
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()

    cmd = [
        WLSUNSET_BIN,
        "-l",
        str(lat),
        "-L",
        str(lon),
    ] + extra_args

    print(f"Starting wlsunset: {' '.join(cmd)}", file=sys.stderr)
    proc = subprocess.Popen(cmd)
    current_lat_lon = lat, lon


async def main():
    bus = await MessageBus(bus_type=BusType.SYSTEM).connect()  # System Bus

    introspection = await bus.introspect(
        "org.freedesktop.GeoClue2", "/org/freedesktop/GeoClue2/Manager"
    )
    manager_obj = bus.get_proxy_object(
        "org.freedesktop.GeoClue2",
        "/org/freedesktop/GeoClue2/Manager",
        introspection,
    )
    manager = manager_obj.get_interface("org.freedesktop.GeoClue2.Manager")

    client_path = await manager.call_get_client()

    client_introspection = await bus.introspect(
        "org.freedesktop.GeoClue2", client_path
    )
    client_obj = bus.get_proxy_object(
        "org.freedesktop.GeoClue2", client_path, client_introspection
    )
    client = client_obj.get_interface("org.freedesktop.GeoClue2.Client")
    properties = client_obj.get_interface("org.freedesktop.DBus.Properties")

    await properties.call_set(
        "org.freedesktop.GeoClue2.Client",
        "DesktopId",
        Variant("s", "wlsunset-geoclue"),
    )
    await properties.call_set(
        "org.freedesktop.GeoClue2.Client",
        "RequestedAccuracyLevel",
        Variant("u", 4),
    )  # City level is enough

    async def get_location_info(path):
        if not path or path == "/":
            return None
        loc_intro = await bus.introspect("org.freedesktop.GeoClue2", path)
        loc_obj = bus.get_proxy_object(
            "org.freedesktop.GeoClue2", path, loc_intro
        )
        loc_props = loc_obj.get_interface("org.freedesktop.DBus.Properties")

        lat = await loc_props.call_get(
            "org.freedesktop.GeoClue2.Location", "Latitude"
        )
        lon = await loc_props.call_get(
            "org.freedesktop.GeoClue2.Location", "Longitude"
        )
        return lat.value, lon.value

    async def update_from_path(path):
        loc = await get_location_info(path)
        if loc:
            update_wlsunset(*loc)

    def on_location_updated(old_path, new_path):
        asyncio.create_task(update_from_path(new_path))

    client.on_location_updated(on_location_updated)

    def on_properties_changed(
        interface_name, changed_properties, invalidated_properties
    ):
        if interface_name == "org.freedesktop.GeoClue2.Client":
            if "Location" in changed_properties:
                asyncio.create_task(
                    update_from_path(changed_properties["Location"].value)
                )

    properties.on_properties_changed(on_properties_changed)

    await client.call_start()

    # Get initial location
    initial_loc_path = await properties.call_get(
        "org.freedesktop.GeoClue2.Client", "Location"
    )
    await update_from_path(initial_loc_path.value)

    try:
        await asyncio.Future()
    except (asyncio.CancelledError, KeyboardInterrupt):
        pass


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
    finally:
        if proc:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
